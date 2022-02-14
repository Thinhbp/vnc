// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract vnc is  ERC20 {

    constructor() public ERC20("vnc", "VNC") {
    }

    address VUSD = 0x98DeAAe8a92eC797942F1b09A4643a740Ed60099;

    bool status ; 
    address owner = msg.sender;


    uint  _tokenInPool ;
    uint  _moneyInPool ;
    enum statusEnum { ICO, IDO, subIDO }
    
    statusEnum state = statusEnum.ICO;
    uint currentStep = 1;
    uint subIDOSold = 0;
    uint constant sqrt2 = 14142135623730951 ;  //1.4142135623730951 = sqrt2/10^16
    uint[30]  icoPrice =[5,10,20,40,80,160,320,640,1280,2560,5120,10240,20480,40960,81920,163840,327680,655360,1310720,2621440,5242880,10485760,20971520,41943040,83886080,167772160,335544320,671088640,1342177280,2684354560];
    uint[30]  tokenBeforeICO = [0,0,3535533905932737,6035533905932738,7803300858899106,9053300858899106,9937184335382290,10562184335382290,11004126073623882,11316626073623882,11537596942744676,11693846942744676,11804332377305075,11882457377305075,11937700094585274,11976762594585274,12004383953225373,12023915203225373,12037725882545423,12047491507545423,12054396847205448,12059279659705448,12062732329535460,12065173735785460,12066900070700466,12068120773825466,12068983941282970,12069594292845470,12070025876574220,12070331052355470] ;
    uint[30]  tokenAfterICO = [0,5000000000000000,8535533905932738,11035533905932738,12803300858899106,14053300858899106,14937184335382290,15562184335382290,16004126073623882,16316626073623882,16537596942744676,16693846942744676,16804332377305075,16882457377305075,16937700094585274,16976762594585274,17004383953225373,17023915203225373,17037725882545423,17047491507545423,17054396847205448,17059279659705448,17062732329535460,17065173735785460,17066900070700466,17068120773825466,17068983941282970,17069594292845470,17070025876574220,17070331052355470] ;
    event buy(address _address, uint _amount);
    event sell(address _address, uint _amount);
    event changestatues(bool _status);
    event changeowner(address _address);


    function currentPrice() public view returns (uint) {
        return _tokenInPool == 0 ? 0 :  _moneyInPool / _tokenInPool  * 1000; // *1000
    }
   
    function checkVUSD() public view returns(uint) {
        return IERC20(VUSD).balanceOf(address(this)) ;
    }

    function buyToken(uint amount) public {
        require(status, " Contract is maintaining") ;
        require(amount > 0, "Please input amount greater than 0");
        require(IERC20(VUSD).allowance(msg.sender, address(this)) == amount,"You must approve in web3");
        require(IERC20(VUSD).transferFrom(msg.sender, address(this),amount), "Transfer failed");

        uint nextBreak;
        uint assumingToken;
        uint buyNowCost = 0;
        uint buyNowToken;

        uint tokenMintInPool = 0;
        uint tokenMintForUser = 0;
        uint tokenTranferForUser = 0;

        while (amount  >  0) {

            if (state == statusEnum.ICO) {
                nextBreak = tokenAfterICO[currentStep] * 10**18 / 10**10 - _tokenInPool;
                assumingToken = amount  / icoPrice[currentStep]  * 100 ;
            }

            if (state == statusEnum.IDO) {
                nextBreak = _tokenInPool - tokenBeforeICO[currentStep + 1] * 10**18 / 10**10;
                assumingToken = _tokenInPool - (_tokenInPool * _moneyInPool) / (_moneyInPool + amount);
            }

            if (state == statusEnum.subIDO) {
                nextBreak =  subIDOSold;
                assumingToken =   _tokenInPool - (_tokenInPool * _moneyInPool) / (_moneyInPool + amount);
            }

            buyNowToken = nextBreak >= assumingToken ? assumingToken : nextBreak;
            buyNowCost = amount;  

            if ( assumingToken>nextBreak ){
	        buyNowCost = state == statusEnum.ICO ? buyNowToken*icoPrice[currentStep] / 100 : ((_tokenInPool * _moneyInPool)/(_tokenInPool - buyNowToken) - _moneyInPool);
            }
            _moneyInPool += buyNowCost;
            if (state == statusEnum.ICO) {
                tokenMintInPool += buyNowToken; 
                tokenMintForUser += buyNowToken;
                _tokenInPool += buyNowToken;
            } else {
                tokenTranferForUser += buyNowToken;
                _tokenInPool -= buyNowToken;
                }

            if (assumingToken >= nextBreak) {
                if (state == statusEnum.ICO) {
                    state = statusEnum.IDO;
                }else if (state == statusEnum.IDO) {
                    state = statusEnum.ICO;
                    currentStep +=1;
                }else {
                    state = statusEnum.ICO;
                    subIDOSold = 0;
                }

            } 

            amount = amount - buyNowCost;

        }
            _mint(address(this), tokenMintInPool);
            _mint(msg.sender, tokenMintForUser);
            IERC20(address(this)).transfer(msg.sender, tokenTranferForUser);
        emit buy(msg.sender, amount);
    }

    function sellToken(uint amount) public {
        require(status, " Contract is maintaining") ;
        require(amount > 0, "Please input amount greater than 0");
        require(approve(address(this),amount), "failed" );
        require(transferFrom(msg.sender, address(this),amount), "Transfer failed");
	    uint currentMoney = _moneyInPool;
        uint moneyInpool = (_tokenInPool * _moneyInPool) / (_tokenInPool + amount);
        uint receivedMoney = currentMoney - moneyInpool ;
        _moneyInPool -= receivedMoney;
        _tokenInPool += amount ; 
        IERC20(VUSD).transfer(msg.sender,receivedMoney );
        if (state == statusEnum.ICO) {
            state = statusEnum.subIDO;
        } 
        if (state == statusEnum.subIDO) {
            subIDOSold +=amount;
        }

        emit sell(msg.sender, amount);
    }

    function changeStatus(bool _status) public {
        require(msg.sender == owner," You are not be allowed");
        status = _status;
        emit changestatues(_status);
    }

    function changeOwner(address _address) public {
        require(msg.sender == owner," You are not be allowed");
        require(_address != address(0), "Address is invalid");
        owner = _address;
        emit changeowner(_address);
    } 
}
