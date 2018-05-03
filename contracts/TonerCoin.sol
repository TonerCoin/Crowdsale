pragma solidity ^0.4.18;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';
import 'zeppelin-solidity/contracts/token/ERC20/BurnableToken.sol';

contract TonerCoin is MintableToken, BurnableToken {

  string public constant name = "TonerCoin";
  string public constant symbol = "TONER";
  uint8 public constant decimals = 18;

}
