// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
contract StoreFund{
   constructor() payable{}

   event Addfund(string name,uint Fundid,uint amount,bool request);
   event acceptfund(string name,uint Fundid,uint amount,bool accepted);
   event Setcomplete(uint Fundid, bool complete);
   

   struct Fund{
        uint id;
        string name;
        uint amount_allocated;
        uint from;
        uint to;
        string IPFS_id;
        bool status;//false if not completed ,true if completed
    
    }

    Fund[] private fundlist;
   //
    mapping(uint => address)   fundOwner;
    mapping(uint => bool )  fundrequested;
    mapping(uint => bool)   fundaccepted;
 
    function addfund(string memory _name, uint _amount , uint _from ,uint _to,string memory _id)external{
        uint _Fundid = fundlist.length;
        fundlist.push(Fund(_Fundid,_name,_amount,_from,_to,_id,false));
        fundOwner[_Fundid] = msg.sender;
        fundrequested[_Fundid]=false;
        fundaccepted[_Fundid]=false;
        emit Addfund(_name,_Fundid,_amount,false);     //what the block will display
    }

   
    function getfundlist(bool _finished) private view returns(Fund[] memory){
        Fund[] memory temporary=new Fund[](fundlist.length);
        uint counter=0;
        for(uint i=0; i<fundlist.length;i++){
            if(fundOwner[i]==msg.sender&&fundlist[i].status==_finished)
            {
                temporary[counter]=fundlist[i];
                counter++;
            }
        }
        Fund[] memory result = new Fund[](counter);
        for(uint i=0;i<counter;i++){
            result[i] = temporary[i];
        }
            return result;
    }
  
    function ongoingFundList() external view returns(Fund[] memory){
        return getfundlist(false);
    }

    function completedFundList() external view returns(Fund[] memory){
        return getfundlist(true);
    }
    function returnIPFS_id(uint _id)external view returns(string memory){
        string memory temp;
        for(uint i=0;i<fundlist.length;i++){
         if(fundlist[i].id==_id){
           temp=fundlist[i].IPFS_id;
       }
        }
       return temp;
    }

   function requestAdmin(uint _id)external  {
       fundrequested[_id]=true;
        emit Addfund(fundlist[_id].name,_id,fundlist[_id].amount_allocated,true);     
   }

   function getrequestedfundlist()external view returns(Fund[] memory){
       Fund[] memory temporary=new Fund[](fundlist.length);
       uint counter=0;
           for(uint i=0; i<fundlist.length;i++){
               if(fundrequested[i]==true&& !fundaccepted[i]){
                temporary[counter]=fundlist[i];
                counter++;
            }
        }
        Fund[] memory result = new Fund[](counter);
        for(uint i=0;i<counter;i++){
            result[i] = temporary[i];
        }
            return result;
    }   
    function setcomplete(uint _id)external{
        fundlist[_id].status=true;
         emit acceptfund(fundlist[_id].name,_id,fundlist[_id].amount_allocated,true);     
    }
    function getfundowner(uint _id)external view returns(address){
         return (fundOwner[_id]);
     }
        
    function sendether(address  payable[] memory _reciever , uint amount , bytes memory _Signature, uint _id)public payable{
        require((_reciever.length*amount)<=msg.value,"the amount sent is less than the required");
        require(verify(address(this),amount,msg.sender,_Signature),"not valid sign");
        fundaccepted[_id]=true;
        for(uint i=0 ; i< _reciever.length; i++)
        { _reciever[i].transfer(amount);
           
        } 
       payable(msg.sender).transfer(address(this).balance);
    }

    function blocknum() public view returns(uint256){
        return block.number;
    }

//***************SIGN VERIFICATION PART******************
//****do this inside transfer function and remove comment
function hashmsg(address _to,uint _amount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked( _to,_amount));//try to get nonce of the block using
    }

    
function signhashmsg(bytes32 _hashmsg)public pure returns (bytes32)
    {
         return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hashmsg));
    }

function verify( address _to,uint _amount ,address _signer, bytes memory _signature)public pure returns(bool){
        bytes32 msghash =hashmsg(_to,_amount);
        bytes32 signedhashmsg= signhashmsg(msghash);

        return recoverSigner(signedhashmsg , _signature) == _signer;
    }

function recoverSigner(bytes32 _signedhashmsg,bytes memory _signature ) public pure returns (address) {
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_signedhashmsg, v, r, s);
    }
function splitSignature(
        bytes memory _sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_sig, 32))
            // second 32 bytes
            s := mload(add(_sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_sig, 96)))
        }
        // implicitly return (r, s, v)
    }

}
