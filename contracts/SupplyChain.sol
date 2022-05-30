// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract SupplyChain {

  address public owner;
  uint256 public skuCount;
  mapping(uint => Item) public items;

  enum State {
    ForSale, 
    Sold, 
    Shipped, 
    Received
  } 

  struct Item {
    string name; 
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }
  
  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint arg);
  event LogReceived(uint arg);
  
  modifier verifyCaller (address _address) { 
    require (msg.sender == _address); 
    _;
  }

  modifier paidEnough(uint _price) { 
    assert(msg.value >= _price); 
    _;
  }

  modifier checkValue(uint _sku) {
    _;
    uint _price = items[_sku].price;
    uint amountToRefund = msg.value - _price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  modifier forSale(uint _sku) {
    require((items[_sku].buyer) == address(0), "Item does not exist");
    require((items[_sku].state == State.ForSale), "Not for sale");
    _;
  }
  
  modifier sold(uint _sku) {
    require(uint(items[_sku].state) == 1, "Item is not sold");
    _;
  } 
  
  modifier shipped(uint _sku) {
    require(uint(items[_sku].state) == 2, "Item is not shipped");
    _;
  } 
  
  modifier received(uint _sku) {
    require(uint(items[_sku].state) == 3, "Item is not received");
    _;
  } 

  constructor() public {
    owner = msg.sender;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {

    items[skuCount] = Item({
     name: _name, 
     sku: skuCount, 
     price: _price, 
     state: State.ForSale, 
     seller:  payable(msg.sender),
     buyer: payable(address(0))
    });
    
    emit LogForSale(skuCount);
    skuCount = skuCount + 1;
    
    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {

    items[sku].state = State.Sold;
    items[sku].buyer = payable(msg.sender);
    (bool sent, ) = (items[sku].seller).call{value: items[sku].price}(""); 
    require(sent, "Failed to send ether");
    emit LogSold(sku);

  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;
    emit LogShipped(sku);
  }

  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;
    emit LogReceived(sku);
  }

  function fetchItem(uint _sku) public view returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
    { 
     name = items[_sku].name; 
     sku = items[_sku].sku; 
     price = items[_sku].price; 
     state = uint(items[_sku].state); 
     seller = items[_sku].seller; 
     buyer = items[_sku].buyer; 
     return (name, sku, price, state, seller, buyer); 
    } 
}
