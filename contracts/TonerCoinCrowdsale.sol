pragma solidity ^0.4.18;

import './TonerCoin.sol';
import 'zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol';

contract TonerCoinCrowdsale is Ownable, MintedCrowdsale {

  using SafeMath for uint256;

  TonerCoin public token;
  uint256 public rateUSDcETH;
  uint256 public softcapUSD;
  uint256 public hardcapUSD;
  uint256 public usdRaised;
  uint8 public constant decimals = 18;
  uint8 public currentTokenPrice;
  bool public icoActive;
  bool public canRefund;
  address public wallet;

  // держатели bounty токенов
  mapping(address => uint256) public bountyBalances;

  // адреса перечислевшие эфир
  mapping (address => uint256) public deposited;

  // количество выпущенных токенов для разных этапов
  uint256 public bountyTokenAmount;
  uint256 public bountyTokenMax = 200000 * (10 ** uint256(decimals));
  uint256 public TokenAmount;
  uint256 public TokenMax;

  // время начала преICO и ICO
  uint256 public preIcoStartTime;
  uint256 public preIcoEndTime;
  uint256 public preIcoFailTime;
  uint256 public icoStartTime;
  uint256 public icoEndTime;
  uint256 public icoRefundTime;

  event RateUpdate(uint256 rate);
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function TonerCoinCrowdsale(
    uint256 _rate,
    address _wallet,
    TonerCoin _token
    )
    public
    Crowdsale(_rate, _wallet, _token) {
      owner = msg.sender;
      rateUSDcETH = _rate;
      token = _token;
      // testing time
      preIcoStartTime = now;
      preIcoEndTime = now + 240;
      preIcoFailTime = now + 360;
      icoStartTime = now + 480;
      icoEndTime =  now + 600;
      icoRefundTime =  now + 720;
      // setup time
      /*
      preIcoStartTime = now;
      preIcoEndTime = 1525824000; // 9 may 2018
      icoStartTime = 1526774400; // 20 may 2018
      icoEndTime =  1563580800; // 20 july 2018
      */
      // ico active
      icoActive = true;
      canRefund = false;

      //softcapUSD  = 20000000;
      // тестовый softcap
      softcapUSD = 5000;

      //hardcapUSD = 300000000;
      // тестовый hardcap
      hardcapUSD = 10000;
  }
  /*==================
  ====MAIN=FUNCTIONS==
  ==================*/
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = calculateTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    TokenAmount = TokenAmount.add(tokens);
    require(TokenAmount <= TokenMax);

    usdRaised = calculateUSDcValue(weiRaised);

    _processPurchase(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    deposited[_beneficiary] = deposited[_beneficiary].add(weiAmount);

    //_forwardFunds(); функция закоментирована, ибо мы возвращаем деньги не на кошелек,
    // создавший смарт-контракт, а на сам сам контракт, чтобы инвесторы в случае чего
    // могли вернуть свой эфир

    _postValidatePurchase(_beneficiary, weiAmount);

  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    // баунти закончилось, устанавливаем
    // лимит токенов
    // и цену за токен - 40 центов
    if(block.timestamp >= preIcoStartTime && block.timestamp < preIcoEndTime) {
      currentTokenPrice = 10;
      TokenMax = 1800000 * (10 ** uint256(decimals));
    }
    // если preICO закончилось и мы не набрали softcap, то завершаем ICO
    if(block.timestamp >= preIcoEndTime && usdRaised < softcapUSD) {
      icoActive = false;
      // в течении двух месяцев после неудачного ICO инвесторы не смогут вернуть свой эфир
      if(block.timestamp < preIcoFailTime) {
        canRefund = true;
      }
      // если время прошло, то инвестор уже не может вернуть эфир
      else {
        canRefund = false;
      }
    }
    // если мы набрали softcap
    // то приостанавливаем продажу токенов
    // и ждем до начала ICO
    if(block.timestamp >= preIcoStartTime && usdRaised >= softcapUSD) {
      icoActive = false;
    }
    // если преICO завершилось успешно, то устанавливаем
    // лимит токенов
    // и цену за токен - 40 центов
    if(block.timestamp >= icoStartTime && usdRaised >= softcapUSD) {
      icoActive = true;
      currentTokenPrice = 40;
      TokenMax = 8000000 * (10 ** uint256(decimals));
    }
    // если не набираем hardcap и время ICO прошло, то
    // завершаем ICO
    if(block.timestamp >= icoEndTime && usdRaised < hardcapUSD) {
      icoActive = false;
    }
    // если набираем hardcap завершаем ICO
    if(block.timestamp > icoStartTime && usdRaised >= hardcapUSD) {
      icoActive = false;
    }

    require(icoActive);

  }

  // передаем эфир со смартконтракте на кошелек
  // функцию возможно вызвать только в том случае
  // если не идет период возрата эфира инвесторам
  // и если наше ico прошло
  function forwardFunds(address _wallet) onlyOwner public {
    require(!canRefund);
    require(block.timestamp >= icoEndTime);
    _wallet.transfer(weiRaised);
  }

  // set rate
  function setRate(uint256 _rateUSDcETH) onlyOwner public {
      rateUSDcETH = _rateUSDcETH;
      RateUpdate(rateUSDcETH);
  }

  // calculate deposit value in USD Cents
  function calculateUSDcValue(uint256 _weiDeposit) public view returns (uint256) {

      // wei per USD cent
      uint256 weiPerUSDc = 1 ether/rateUSDcETH;

      // Deposited value converted to USD cents
      uint256 depositValueInUSDc = _weiDeposit.div(weiPerUSDc);
      return depositValueInUSDc;
  }
  // вычисляем количество wei по курсу доллара
  function calculateWeiFromUSDc(uint256 _usdcDeposit) public view returns (uint256) {

      uint256 usdcPerEth = rateUSDcETH * 1 ether;

      uint256 depositUSDcInEth = usdcPerEth.div(_usdcDeposit);
      return depositUSDcInEth;

  }
  // calculates how much tokens will beneficiary get
  // for given amount of wei
  function calculateTokenAmount(uint256 _weiDeposit) public view returns (uint256) {
      uint256 mainTokens = calculateUSDcValue(_weiDeposit) * (10 ** uint256(decimals));
      mainTokens = mainTokens.div(currentTokenPrice);
      return mainTokens;
  }
  // токены которые мы распределяем команде баунти
  // до начала преICO
  function sendBountyTokens(address _beneficiary, uint256 _tokenAmount) onlyOwner public returns (uint256)  {
    require(block.timestamp < preIcoStartTime);
    bountyTokenAmount = bountyTokenAmount.add(_tokenAmount);
    // лимит на раздачу баунти-токенов
    require(bountyTokenAmount <= bountyTokenMax);
    token.mint(_beneficiary, _tokenAmount);
    return bountyTokenMax.sub(bountyTokenAmount);
  }

  function refund() public returns (bool) {
    require(canRefund);
    address investor = msg.sender;
    uint256 depositedValue = deposited[investor];
    require(depositedValue > 0);
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);

    return true;
  }


  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
}
