//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Unichecker.sol";

contract IkonicVesting is Ownable,ReentrancyGuard,uniChecker {

    IERC20 public token;

    uint256 public startDate;
    uint256 public activeLockDate;
    bool isremoved;
    bool public isStart;
    mapping(address=>bool) public isSameInvestor;
    address public signer;
    mapping(address=>uint) public timestampp;

    mapping(address=>mapping(uint=>bool)) public usedNonce;

    uint[11] public lockEnd;//=[0,seedLockEndDate,strategicLockEndDate,privateLockEndDate,publicLockEndDate,advisorsLockEndDate,teamLockEndDate,ecosystemLockEndDate,developmentLockEndDate,marketingLockEndDate,liquidityLockEndDate];

    uint[11] public vestEnd;//=[0,seedVestingEndDate,strategicVestingEndDate,privateVestingEndDate,publicVestingEndDate,advisorsVestingEndDate,teamVestingEndDate,ecosystemVestingEndDate,developmentVestingEndDate,marketingVestingEndDate,liquidityVestingEndDate];
    uint256 day = 1 minutes;

    modifier setStart{
        require(isStart==true,"wait for start");
        _;
    }

    event TokenWithdraw(address indexed buyer, uint value);
    event InvestersAddress(address accoutt, uint _amout,uint saletype);

    mapping(address => InvestorDetails) public Investors;



    uint256 public seedStartDate;
    uint256 public strategicStartDate;
    uint256 public privateStartDate;
    uint256 public publicStartDate;
    uint256 public advisorsStartDate;
    uint256 public teamStartDate;
    uint256 public ecosystemStartDate;
    uint256 public developmentStartDate;
    uint256 public marketingStartDate;
    uint256 public liquidityStartDate;

    uint public intermediateRelease;

    uint256 public seedLockEndDate;
    uint256 public strategicLockEndDate;
    uint256 public privateLockEndDate;
    uint256 public publicLockEndDate;
    uint256 public advisorsLockEndDate;
    uint256 public teamLockEndDate;
    uint256 public ecosystemLockEndDate;
    uint256 public developmentLockEndDate;
    uint256 public marketingLockEndDate;
    uint256 public liquidityLockEndDate;

    uint256 public seedVestingEndDate;
    uint256 public strategicVestingEndDate;
    uint256 public privateVestingEndDate;
    uint256 public publicVestingEndDate;
    uint256 public advisorsVestingEndDate;
    uint256 public teamVestingEndDate;
    uint256 public ecosystemVestingEndDate;
    uint256 public developmentVestingEndDate;
    uint256 public marketingVestingEndDate;
    uint256 public liquidityVestingEndDate;

    receive() external payable {
    }

    /* Withdraw the contract's BNB balance to owner wallet*/
    function extractBNB() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function getInvestorDetails(address _addr) public view returns(InvestorDetails memory){
        return Investors[_addr];
    }


    function getContractTokenBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }


    /* 
        Transfer the remining token to different wallet. 
        Once the ICO is completed and if there is any remining tokens it can be transfered other wallets.
    */
    function transferToken(address ERC20Address, uint256 value) public onlyOwner {
        require(value <= IERC20(ERC20Address).balanceOf(address(this)), 'Insufficient balance to withdraw');
        IERC20(ERC20Address).transfer(msg.sender, value);
    }

    /* Utility function for testing. The token address used in this ICO contract can be changed. */
    function setTokenAddress(address _addr) public onlyOwner {
        token = IERC20(_addr);
    }


    struct Investor {
        address account;
        uint256 amount;
        uint256 saleType;
    }

    struct InvestorDetails {
        uint256 totalBalance;
        uint256 timeDifference;
        uint256 lastVestedTime;
        uint256 remainingUnitsToVest;
        uint256 tokensPerUnit;
        uint256 vestingBalance;
        uint256 investorType;
        uint256 initialAmount;
        bool isInitialAmountClaimed;
    }
    //remainingUnitsToVest = [0,365,300,1095,240,730,180]
    uint[] public saleTypeUnitsToVest = [0,660,540,365,180,900,1095,1050,730,1350,480];
    uint[] public saleTypeMultiplier = [0,0,5,10,20,0,0,0,6,3,20];
    uint[] public saleTypeTimeframe = [0,660,540,365,180,900,1095,1050,730,1350,480];

    // seedVestingEndDate = seedLockEndDate + 660 minutes;
    // strategicVestingEndDate = strategicLockEndDate  + 540 minutes;
    // privateVestingEndDate = privateLockEndDate + 365 minutes;
    // publicVestingEndDate = publicLockEndDate + 180 minutes;
    // advisorsVestingEndDate = advisorsLockEndDate + 900 minutes;
    // teamVestingEndDate = teamLockEndDate + 1095 minutes;
    // ecosystemVestingEndDate = ecosystemLockEndDate + 1050 minutes;
    // developmentVestingEndDate = developmentLockEndDate + 730 minutes;
    // marketingVestingEndDate = marketingLockEndDate + 1350 minutes;
    // liquidityVestingEndDate = liquidityLockEndDate + 480 minutes;

    function adminAddInvestors(Investor[] memory investorArray) public onlyOwner{
        for(uint16 i = 0; i < investorArray.length; i++) {

            if(isremoved){
                isSameInvestor[investorArray[i].account]=true;
                isremoved=false;
            }
            else{
                require(!isSameInvestor[investorArray[i].account],"Investor Exist");
                isSameInvestor[investorArray[i].account]=true;
            }
            uint256 saleType = investorArray[i].saleType;
            InvestorDetails memory investor;
            investor.totalBalance = (investorArray[i].amount) * (10 ** 18);
            investor.investorType = investorArray[i].saleType;
            investor.vestingBalance = investor.totalBalance;

            investor.remainingUnitsToVest = saleTypeUnitsToVest[saleType];
            investor.initialAmount = (investor.totalBalance * saleTypeMultiplier[saleType]) / 100;
            investor.tokensPerUnit = ((investor.totalBalance)- (investor.initialAmount))/saleTypeTimeframe[saleType];

            Investors[investorArray[i].account] = investor;
            emit InvestersAddress(investorArray[i].account,investorArray[i].amount, investorArray[i].saleType);
        }
    }
    uint public MiddleRelease;
    function addInvestors(Ikonic memory ikonic) external{
        require(getSigner(ikonic)==signer,"!signer");
        require(ikonic.userAddress==msg.sender,"!User");
        require(!usedNonce[msg.sender][ikonic.timestamp],"Nonce Used");
        usedNonce[msg.sender][ikonic.timestamp]=true;


        if(isremoved){
            isSameInvestor[ikonic.userAddress]=true;
            isremoved=false;
        }
        else{
            require(!isSameInvestor[ikonic.userAddress],"Investor Exist");
            isSameInvestor[ikonic.userAddress]=true;
        }
        uint256 saleType = ikonic.saleType;
        InvestorDetails memory investor;
        investor.totalBalance = (ikonic.amount) * (10 ** 18);
        investor.investorType = ikonic.saleType;
        investor.vestingBalance = investor.totalBalance;

        investor.remainingUnitsToVest = saleTypeUnitsToVest[saleType];
        investor.initialAmount = (investor.totalBalance * saleTypeMultiplier[saleType]) / 100;
        investor.tokensPerUnit = ((investor.totalBalance)- (investor.initialAmount))/saleTypeTimeframe[saleType];

        Investors[ikonic.userAddress] = investor;
        emit InvestersAddress(ikonic.userAddress,ikonic.amount,ikonic.saleType);
    }



    function withdrawTokens() public   nonReentrant setStart {
        require(block.timestamp >=seedStartDate,"wait for start date");
        require(Investors[msg.sender].investorType >0,"Investor Not Found");
        if(
            Investors[msg.sender].isInitialAmountClaimed ||
            Investors[msg.sender].investorType == 1 ||
            Investors[msg.sender].investorType == 5 ||
            Investors[msg.sender].investorType == 6 ||
            Investors[msg.sender].investorType == 7
        ) {

            require(block.timestamp>=lockEnd[Investors[msg.sender].investorType],"wait until lock period complete");
            activeLockDate = lockEnd[Investors[msg.sender].investorType] ;
            /* Time difference to calculate the interval between now and last vested time. */
            uint256 timeDifference;
            if(Investors[msg.sender].lastVestedTime == 0) {
                require(activeLockDate > 0, "Active lockdate was zero");
                timeDifference = (block.timestamp) - (activeLockDate);
            } else {
                timeDifference = (block.timestamp) -(Investors[msg.sender].lastVestedTime);
            }

            /* Number of units that can be vested between the time interval */
            uint256 numberOfUnitsCanBeVested = (timeDifference)/(day);

            /* Remining units to vest should be greater than 0 */
            require(Investors[msg.sender].remainingUnitsToVest > 0, "All units vested!");

            /* Number of units can be vested should be more than 0 */
            require(numberOfUnitsCanBeVested > 0, "Please wait till next vesting period!");

            if(numberOfUnitsCanBeVested >= Investors[msg.sender].remainingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[msg.sender].remainingUnitsToVest;
            }

            /*
                1. Calculate number of tokens to transfer
                2. Update the investor details
                3. Transfer the tokens to the wallet
            */
            uint256 tokenToTransfer = numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            uint256 remainingUnits = Investors[msg.sender].remainingUnitsToVest; //remainingUnits === remainingAmount
            uint256 balance = Investors[msg.sender].vestingBalance; //balance === tokensToTransfer
            
//            (uint tokensToTransfer, uint remainingAmount, uint Balance, uint vestingLeft) = getAvailableBalance(msg.sender);
            Investors[msg.sender].remainingUnitsToVest -= numberOfUnitsCanBeVested;
            Investors[msg.sender].vestingBalance -= numberOfUnitsCanBeVested * Investors[msg.sender].tokensPerUnit;
            Investors[msg.sender].lastVestedTime = block.timestamp;
            if(numberOfUnitsCanBeVested == remainingUnits) {
                token.transfer(msg.sender, balance);
                emit TokenWithdraw(msg.sender, balance);
            } else {
                token.transfer(msg.sender, tokenToTransfer);
                emit TokenWithdraw(msg.sender, tokenToTransfer);
            }
        }
        else {
            if(Investors[msg.sender].investorType!=8){
                require(!Investors[msg.sender].isInitialAmountClaimed, "Amount already withdrawn!");
                require(block.timestamp >seedStartDate,"wait for start date");
                Investors[msg.sender].vestingBalance -= Investors[msg.sender].initialAmount;
                Investors[msg.sender].isInitialAmountClaimed = true;

                uint256 amount = Investors[msg.sender].initialAmount;
                Investors[msg.sender].initialAmount = 0;
                token.transfer(msg.sender, amount);
                emit TokenWithdraw(msg.sender, amount);}
            else{
                require(block.timestamp>intermediateRelease+day,"wait for intermediate release");
                require(block.timestamp>timestampp[msg.sender]+day,"wait for 1 day"); // block.timestamp > 0+day;
                uint pending;
                if (timestampp[msg.sender]>0)
                pending = (intermediateRelease-timestampp[msg.sender])/60; //(1654837500 - 0)/60
                else
                pending = ((block.timestamp - intermediateRelease)/60);
                uint256 amountDay = pending * ((Investors[msg.sender].initialAmount)/30); // 3 * 60/30 = 6
                timestampp[msg.sender]=block.timestamp;
                if(block.timestamp>intermediateRelease+30 * day){
                    Investors[msg.sender].isInitialAmountClaimed = true;
                }
                token.transfer(msg.sender,amountDay);
            }
        }
    }

    function setSigner(address _address) external onlyOwner{
        signer=_address;
    }
    function setDates(uint256 StartDate,bool _isStart) public onlyOwner{

        isStart=_isStart;

        seedStartDate = StartDate;
        strategicStartDate = StartDate;
        privateStartDate = StartDate;
        publicStartDate = StartDate;
        advisorsStartDate = StartDate;
        teamStartDate = StartDate;
        ecosystemStartDate = StartDate;
        developmentStartDate = StartDate;
        marketingStartDate = StartDate;
        liquidityStartDate = StartDate;

        intermediateRelease = developmentStartDate + 2 minutes;


        seedLockEndDate = seedStartDate + 2 minutes;
        strategicLockEndDate = strategicStartDate + 1 minutes;
        privateLockEndDate = privateStartDate + 1 minutes;
        publicLockEndDate = publicStartDate + 1 minutes;
        advisorsLockEndDate = advisorsStartDate + 4 minutes;
        teamLockEndDate = teamStartDate + 6 minutes;
        ecosystemLockEndDate = ecosystemStartDate + 1 minutes;
        developmentLockEndDate = developmentStartDate + 2 minutes;
        marketingLockEndDate = marketingStartDate + 3 minutes;
        liquidityLockEndDate = liquidityStartDate + 1 minutes;




        seedVestingEndDate = seedLockEndDate + 660 minutes;
        strategicVestingEndDate = strategicLockEndDate  + 540 minutes;
        privateVestingEndDate = privateLockEndDate + 365 minutes;
        publicVestingEndDate = publicLockEndDate + 180 minutes;
        advisorsVestingEndDate = advisorsLockEndDate + 900 minutes;
        teamVestingEndDate = teamLockEndDate + 1095 minutes;
        ecosystemVestingEndDate = ecosystemLockEndDate + 1050 minutes;
        developmentVestingEndDate = developmentLockEndDate + 730 minutes;
        marketingVestingEndDate = marketingLockEndDate + 1350 minutes;
        liquidityVestingEndDate = liquidityLockEndDate + 480 minutes;

        vestEnd =[0,seedVestingEndDate,strategicVestingEndDate,privateVestingEndDate,publicVestingEndDate,advisorsVestingEndDate,teamVestingEndDate,ecosystemVestingEndDate,developmentVestingEndDate,marketingVestingEndDate,liquidityVestingEndDate];
        lockEnd = [0,seedLockEndDate,strategicLockEndDate,privateLockEndDate,publicLockEndDate,advisorsLockEndDate,teamLockEndDate,ecosystemLockEndDate,developmentLockEndDate,marketingLockEndDate,liquidityLockEndDate];


    }

    function setDay(uint256 _value) public onlyOwner {
        day = _value;
    }


    function removeSingleInvestor(address  _addr) public onlyOwner{
        isremoved=true;
        require(!isStart,"Vesting Started , Unable to Remove Investor");
        require(Investors[_addr].investorType >0,"Investor Not Found");
        delete Investors[_addr];
    }

    function removeMultipleInvestors(address[] memory _addr) external onlyOwner{
        for(uint i=0;i<_addr.length;i++){
            removeSingleInvestor(_addr[i]);
        }
    }

    function getAvailableBalance(address _addr) external view returns(uint256, uint256, uint256){
        uint VestEnd=vestEnd[Investors[_addr].investorType];
        uint lockDate=lockEnd[Investors[_addr].investorType];
        if(Investors[_addr].isInitialAmountClaimed || Investors[_addr].investorType == 1 || Investors[_addr].investorType == 5 || Investors[_addr].investorType == 6 || Investors[_addr].investorType == 7){
            uint hello = day;
            uint timeDifference;
            // uint lockDateTeam = teamLockEndDate;
            if(Investors[_addr].lastVestedTime == 0) {

                if(block.timestamp>=VestEnd)return(Investors[_addr].remainingUnitsToVest*Investors[_addr].tokensPerUnit,0,0);
                if(block.timestamp<lockDate) return(0,0,0);
                if(lockDate + day> 0)return (((block.timestamp-lockDate)/day) *Investors[_addr].tokensPerUnit,0,0);//, "Active lockdate was zero");
                timeDifference = (block.timestamp) -(lockDate);}
            else{
                timeDifference = (block.timestamp) - (Investors[_addr].lastVestedTime);
            }
            uint numberOfUnitsCanBeVested;
            uint tokenToTransfer ;
            numberOfUnitsCanBeVested = (timeDifference)/(hello);
            if(numberOfUnitsCanBeVested >= Investors[_addr].remainingUnitsToVest) {
                numberOfUnitsCanBeVested = Investors[_addr].remainingUnitsToVest;
            }
            tokenToTransfer = numberOfUnitsCanBeVested * Investors[_addr].tokensPerUnit;
            uint remainingUnits = Investors[_addr].remainingUnitsToVest;
            uint balance = Investors[_addr].vestingBalance;
            if(numberOfUnitsCanBeVested == remainingUnits) return(balance,0,0) ;
            else return(tokenToTransfer,remainingUnits,balance);
        }
        else {
            if (Investors[_addr].investorType == 8) {
                if(block.timestamp>intermediateRelease+day) return (0,0,0);
                if(block.timestamp>timestampp[msg.sender]+day) return (0,0,0);//,"wait for 1 day"); // block.timestamp > 0+day;
                uint pending;
                if (timestampp[msg.sender]>0)
                    pending = (intermediateRelease-timestampp[msg.sender])/60; //(1654837500 - 0)/60
                else
                    pending = ((block.timestamp - intermediateRelease)/60);
                uint256 amountDay = pending * ((Investors[msg.sender].initialAmount)/30); // 3 * 60/30 = 6
               return (amountDay,0,0);
            }
            if(!isStart)return(0,0,0);
            if(block.timestamp<seedStartDate)return(0,0,0);
            Investors[_addr].initialAmount == 0 ;
            return (Investors[_addr].initialAmount,0,0);
        }
        
    }

}