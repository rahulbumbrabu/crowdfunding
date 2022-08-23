// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}

contract CrowdFund{
    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Pay(uint indexed id, address indexed caller, uint amount);
    event Collect(uint id);
    event Payback(uint indexed id, address indexed caller, uint amount);

    struct Campaign{
        address creator;
        uint goal;
        uint payed;
        uint32 startAt;
        uint32 endAt;
        bool collected;

    }

    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public payableAmount;

    constructor(address _token){
        token = IERC20(_token);
    }
    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "");
        require(_endAt >= _startAt, "");
        require(_endAt <= block.timestamp + 2 days, "");
        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            payed: 0,
            startAt: _startAt,
            endAt: _endAt,
            collected: false

        });
    
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);

    }

    function pay(uint _id, uint _amount) external{
            Campaign storage campaign = campaigns[_id];
            require(block.timestamp >= campaign.startAt, "");
            require(block.timestamp <= campaign.endAt, "");

            campaign.payed += _amount;
            payableAmount[_id][msg.sender] += _amount;
            token.transferFrom(msg.sender, address(this), _amount);

            emit Pay(_id, msg.sender, _amount);
    }

    function collect(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(msg.sender == campaign.creator, "");
        require(block.timestamp > campaign.endAt, "");
        require(campaign.payed >= campaign.goal, "");
        require(!campaign.collected, "");

        campaign.collected = true;
         token.transfer(msg.sender, campaign.payed);

         emit Collect(_id);


    }
    function payback(uint _id) external{
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "");
        require(campaign.payed < campaign.goal, "");

        uint balance  = payableAmount[_id][msg.sender];
        payableAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, balance);

        emit Payback(_id, msg.sender, balance);

    }
}