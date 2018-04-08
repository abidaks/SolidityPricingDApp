/*
    Copyright 2017, Muhammad Abid

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title Pricing Package Contract
/// @author Muhammad Abid - <mohdabid.aks@gmail.com>

pragma solidity ^0.4.10;

import "./SafeMath.sol";

contract SimplePricing {

	using SafeMath for uint256;
	
	uint private totalAmount;
	uint public tone;
	uint public ttwo;
	uint public tthree;
	address public owner;
	
	/*
		User saves information about the payer
		totalAmountPaid - Total amount paid
		packageAmount - Package in which user subscribed
		isActive - Is active
		paidDate - Last payment date
	*/
	
	struct User {
		uint256 totalAmountPaid;
		uint256 packageAmount;
		bool isActive;
		uint256 paidDate;
	}
	
	mapping(address => User) private Users;
	
	//constructor
	
	function SimplePricing(uint _tone, uint _ttwo, uint _tthree) public {
		owner = msg.sender;
		totalAmount = 0;
		tone = _tone;
		ttwo = _ttwo;
		tthree = _tthree;
	}
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
    }
	
	/*
		This function update the packages prices
		Only owner is allowed
	*/
	function UpdatePricing(uint _tone, uint _ttwo, uint _tthree) public onlyOwner {
		tone = _tone;
		ttwo = _ttwo;
		tthree = _tthree;
	}
	
	/*
		This function end this contract only if there are no funds in the contract
		Only owner is allowed
	*/
	function kill() public onlyOwner {
		require(totalAmount == 0);
		if(msg.sender == owner) selfdestruct(owner);
	}
	
	/*
		This function is used for payments
	*/
	
	function payNow(uint256 _value, address _payer) internal returns (bool){
		if(checkIfExists(_payer)){
			Users[_payer].totalAmountPaid = Users[_payer].totalAmountPaid.add(_value);
			Users[_payer].paidDate = now;
		}else{
			Users[_payer].totalAmountPaid = _value;
			Users[_payer].packageAmount = _value;
			Users[_payer].isActive = true;
			Users[_payer].paidDate = now;
		}
		totalAmount = totalAmount.add(_value);
		return true;
	}
	
	/*
		This function check if given user exists
	*/
	function checkIfExists(address _user) internal view returns (bool){
		if(Users[_user].isActive){
			return true;
		}
		return false;
	}
	
	/*
		This function is used to pay the subscribed amount
	*/
	function paySubscription() public payable returns (bool){
		require(checkIfExists(msg.sender));
		require(Users[msg.sender].packageAmount == msg.value);
		
		payNow(Users[msg.sender].packageAmount, msg.sender);
		emit MonthlyPayment(msg.sender, msg.value, Users[msg.sender].paidDate);
		return true;
	}
	
	/*
		This function is used to pay.
	*/
	function pay() public payable returns (bool){
		uint256 _value = msg.value;
		if(_value == tone || _value == ttwo || _value == tthree){
			payNow(_value, msg.sender);
			emit Subscribed(msg.sender, _value);
			return true;
		}else{
			return false;
		}
	}
	
	/*
		Transfer the funds to owner account
		Only owner is allowed
	*/
	function transferAmount() public onlyOwner payable returns (bool){
		require(totalAmount > 0);
		msg.sender.transfer(totalAmount);
		totalAmount = 0;
		return true;
	}
	
	/*
		Get total ether earned by this contract
		Only owner is allowed
	*/
	function getTotal() public view onlyOwner returns(uint256) {
		return totalAmount;
	}
	
	/*
		Check if any given address is active or not
		Only owner is allowed
	*/
	function getUserByAdr(address _user) public view onlyOwner returns (bool){
		return Users[_user].isActive;
	}
	
	/*
		Default payable function
	*/
	function () public payable {
		paySubscription();
	}
	
	/*
		This function checks if the user exists and returns
		@_total -- Total paid by this user
		@_package -- Selected package of this user in terms of how much ether paid.
		@_paidOn -- Last payment date
		@_active -- Is this user Active or not?
	*/
	
	function getUser() view public returns (uint256 _total, uint256 _package, uint256 _paidOn, bool _active){
		if(checkIfExists(msg.sender)){
			return (Users[msg.sender].totalAmountPaid, Users[msg.sender].packageAmount, Users[msg.sender].paidDate, Users[msg.sender].isActive);
		}else{
			return (0, 0, 0, false);
		}
	}
	
	event Subscribed(address _from, uint256 _value);
	event MonthlyPayment(address _from, uint256 _value, uint256 _lastPayment);
}