pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
  uint256 public totalSupply_;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }
  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract TonerCoin is ERC20, Ownable {
  using SafeMath for uint256;
  
  event Burn(address indexed burner, uint256 value);
  event Mint(address indexed to, uint256 amount);
  event MinterAdded(address indexed newMinter);
  event MinterRemoved(address indexed removedMinter);

  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) internal allowed;
  mapping(address => bool) minters;

  string public constant name = "TonerCoin";
  string public constant symbol = "TONER";
  uint8 public constant decimals = 18;
  
  /**
  * @dev Adds minter role to address (able to create new tokens)
  * @param _address The address that will get minter privileges
  */
  function addMinter(address _address) onlyOwner public {
    minters[_address] = true;
    MinterAdded(_address);
  }

  /**
  * @dev Removes minter role from address
  * @param _address The address to remove minter privileges
  */
  function delMinter(address _address) onlyOwner public {
    minters[_address] = false;
    MinterRemoved(_address);
  }

  /**
  * @dev Throws if called by any account other than the minter.
  */
  modifier onlyMinter() {
    require(minters[msg.sender]);
    _;
  }
  
  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
 * @dev Transfer tokens from one address to another
 * @param _from address The address which you want to send tokens from
 * @param _to address The address which you want to transfer to
 * @param _value uint256 the amount of tokens to be transferred
 */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

    
  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
  
   /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyMinter public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
  
}

contract TonerCoinCrowdsale is Ownable {
    
    using SafeMath for uint256;
    
    TonerCoin public token;
    
    address public wallet;
    
    uint256 public rateUSDcETH;
    uint256 public softcapUSDc;
    uint256 public hardcapUSDc;
    uint256 public usdcRaised;
    uint256 public weiRaised;
    
    uint256 public startTime;
    uint256 public endTime;
    uint256 public refundTime;
    
    uint256 public tokenAmount;
    uint256 public tokenMax;
    
    mapping (address => uint256) public deposited;
    
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
    event RateUpdate(uint256 rate);
    event Refunded(address indexed beneficiary, uint256 weiAmount);
    
    function TonerCoinCrowdsale(address _tokenAddress, uint256 _rate) public {
        require(_tokenAddress != address(0));
        token = TonerCoin(_tokenAddress);
        rateUSDcETH = _rate;
        wallet = msg.sender;
        
        
        startTime = 1530403200; // 01.07.2018 00:00
        endTime = 1533081540; // 31.07.2018 23:59
        refundTime = 1538438340; // 31.09.2018 23:59
        softcapUSDc = 5000000; // 50.000 $
        hardcapUSDc = 30000000; // 300.000 $
        
        tokenMax = 3000000 * (10 ** 18);
    }
    
    function () external payable {
        buyTokens(msg.sender);
    }
    
    function buyTokens(address _beneficiary) public payable {
        
        require(_beneficiary != address(0));
        require(msg.value != 0);
        require(now <= endTime);
        require(usdcRaised <= hardcapUSDc);
        
        uint256 tokens = calculateTokenAmount(msg.value);
        tokenAmount = tokenAmount.add(tokens);
        require(tokenAmount <= tokenMax);
        
        weiRaised = weiRaised.add(msg.value);
        usdcRaised = calculateUSDcValue(weiRaised);
        
        token.mint(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, msg.value, tokens);
        deposited[_beneficiary] = deposited[_beneficiary].add(msg.value);
        
    
    }
    
    function setRate(uint256 _rateUSDcETH) onlyOwner public {
      rateUSDcETH = _rateUSDcETH;
      RateUpdate(rateUSDcETH);
    }
    
    function calculateUSDcValue(uint256 _weiDeposit) public view returns (uint256) {
      uint256 weiPerUSDc = 1 ether/rateUSDcETH;
      uint256 depositValueInUSDc = _weiDeposit.div(weiPerUSDc);
      return depositValueInUSDc;
    }
    
    function calculateTokenAmount(uint256 _weiDeposit) public view returns (uint256) {
      uint256 tokens = calculateUSDcValue(_weiDeposit) * (10 ** 18);
      tokens = tokens.div(10); // 10 cents per token
      return tokens;
    }
    
    function refund() public returns (bool) {
        require(now > endTime);
        require(now < refundTime);
        require(usdcRaised < softcapUSDc);
        uint256 depositedValue = deposited[msg.sender];
        require(depositedValue > 0);
        deposited[msg.sender] = 0;
        msg.sender.transfer(depositedValue);
        Refunded(msg.sender, depositedValue);
        return true;
    }
    
    function forwardFunds(uint256 _value) public onlyOwner returns (bool) {
        if(usdcRaised < softcapUSDc) {
            require(now > refundTime);
        }
        else {
            wallet.transfer(_value);
        }
        
        return true;
    }
    
    
}