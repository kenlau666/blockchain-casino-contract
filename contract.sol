pragma solidity >=0.7.0 <0.9.0;

contract casino
{
    uint public start_time; 
    uint public play_time;
    uint public auth_time;
    uint public bet_time;
    uint public end_time;
    address payable dealer; // the casino
    uint[16] public e_r; // encrypted r
    uint[16] public d_r; // decrypted r given the private key
    uint16 public r_int; // r in decimal form
    uint public t; // number of authority player
    uint public n; // number of normal player
    uint public a_num_player; // count the current number of authority player
    uint[16] public r; // r in binary form
    uint public c; // count the number of bettor
    bool public cheated = false;
    bool dealer_withdraw = false;
    bool revealed = false;
    uint[2] public p_key;
    uint[2] public s_key;
    uint won; // how much the casino won
    mapping (address=>bool) bettors; // to state the bettor has player
    mapping (address=>bool) results; // the result of the bet
    mapping (address=>bool) collected; // to check if the better has collected the reward or compensation
    mapping (address=>bool) players; // to state the player has participated
    mapping (address=>uint[16]) players_r; // the encrypted ri of player
    mapping (address=>bool) players_h; // to check if the player is honest
    mapping (address=>bool) players_c; // to check if the player has collected the reward
    mapping (address=>uint) k; // k of each bettor
    mapping (address=>bool) x; // to check if the result is generated by srand and rand

    constructor(address payable _dealer, uint _x, uint _n) payable
    {
        require(msg.value > 10000 ether);
        start_time = block.timestamp;
        play_time = start_time + 1 hours;
        auth_time = play_time + 1 hours;
        bet_time = auth_time + 8 hours;
        end_time = start_time + 24 hours;
        dealer = _dealer;
        p_key[0] = _x;
        p_key[1] = _n;
    }

    function deposit_player(uint[16] calldata _r) public payable // for casino player and normal player
    {
        require(block.timestamp < play_time && block.timestamp > start_time);
        require(msg.value == 0.01 ether);
        players[msg.sender] = true;
        players_r[msg.sender] = _r;
        players_c[msg.sender] = false;
        players_h[msg.sender] = false;
        n++;
        for(uint i=0;i<16;++i)
        {
            e_r[i] = e_r[i]*_r[i];
        }
    }

    function update_t() public // make sure authority control at least half of the players
    {
        require(t==0); // only update once
        require(block.timestamp < auth_time && block.timestamp > play_time);
        t = n/2 + 1;
    }

    function deposit_aplayer(uint[16] calldata _ar) public payable // for authority player
    {
        require(block.timestamp < auth_time && block.timestamp > play_time);
        require(msg.value == 0.01 ether);
        players[msg.sender] = true;
        players_r[msg.sender] = _ar;
        players_c[msg.sender] = false;
        players_h[msg.sender] = false;
        a_num_player++;
        for(uint i=0;i<16;++i)
        {
            e_r[i] = e_r[i]*_ar[i];
        }
    }


    function deposit_bettor(uint _k) public payable // to join a bet
    {
        require(block.timestamp < bet_time && block.timestamp > auth_time);
        require(a_num_player >= t); // make sure authority control at least half of the players
        require(c<=10000/0.02);
        require(msg.value==0.01 ether);
        c++;
        bettors[msg.sender] = true;
        k[msg.sender] = _k;
        results[msg.sender] = false;
        collected[msg.sender] = false;
    }

    function give_result(bool x2, address bb) public
    {
        require(msg.sender == dealer);
        require(bettors[bb]);
        results[bb] = x2;
        if(!x2) won+=0.02 ether;
    }

    function reveal_r_sk(uint[16] calldata rr, uint _p, uint _q, uint16 _r_int) public
    {
        require(block.timestamp > bet_time && block.timestamp < end_time);
        require(!revealed);
        require(msg.sender == dealer);
        r = rr;
        s_key[0] = _p;
        s_key[1] = _q;
        revealed = true;
        r_int = _r_int;
        if (_p*_q != p_key[1]) cheated = true; // check if the private key is correct
        if (p_key[0]**((s_key[0]-1)/2)%s_key[0]==1 || p_key[0]**((s_key[1]-1)/2)%s_key[1]==1) cheated = true;
    }
    
    function withdraw_bettors() public
    {
        require(block.timestamp > bet_time && block.timestamp < end_time);
        require(results[msg.sender]);
        require(!collected[msg.sender]);
        collected[msg.sender] = true;
        (bool sent, bytes memory data) = msg.sender.call{value: 0.02 ether}("");
        require(sent);
    }

    function verify_r() public
    {
        require(revealed);
        for(uint i=0;i<16;++i)
        {
            if(e_r[i]**((s_key[0]-1)/2)%s_key[0]==1 && e_r[i]**((s_key[1]-1)/2)%s_key[1]==1)
            {
                d_r[i] = 0;
            }
            else d_r[i] = 1;

            if(r[i] != d_r[i]) cheated = true;
        }
    }

    function verify_x() public
    {
        require(revealed);
        require(bettors[msg.sender]);
        srand(k[msg.sender],r_int);
        int _x;
        // _x = rand(); i dont know how to fix the syntax error
        if (_x%2==0) x[msg.sender] = true;
        else x[msg.sender] = false;

        if(x[msg.sender]!=results[msg.sender]) cheated = true;
    }

    function reveal_player(uint[16] calldata real_ri) public
    {
        require(revealed);
        require(players[msg.sender]);
        players_h[msg.sender] = true;
        for(uint i=0;i<16;++i)
        {
            if(players_r[msg.sender][i]**((s_key[0]-1)/2)%s_key[0]==1 && players_r[msg.sender][i]**((s_key[1]-1)/2)%s_key[1]==1)
            {
                if(real_ri[i]!=0) players_h[msg.sender] = false;
            }
            else
            {
                if(real_ri[i]!=1) players_h[msg.sender] = false;
            }
        }
    }

    function withdraw_players() public
    {
        require(block.timestamp < end_time);
        require(players_h[msg.sender]);
        require(!players_c[msg.sender]);
        players_c[msg.sender] = true;
        uint reward = won/10/(n+a_num_player) + 0.02 ether;
        (bool sent, bytes memory data) = msg.sender.call{value: reward}("");
        require(sent);
    }

    function withdraw_dealer() public
    {
        require(block.timestamp > end_time);
        require(msg.sender == dealer);
        require(!dealer_withdraw);
        require(!cheated && revealed);
        dealer_withdraw = true;
        (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
        require(sent);
    }

    function srand(uint kk, uint rrr) public
    {

    }

    function rand() public
    {

    }

    function compensate() public
    {
        require(block.timestamp > end_time);
        require(cheated || !revealed);
        require(!collected[msg.sender]);
        collected[msg.sender] = true;
        (bool sent, bytes memory data) = msg.sender.call{value: 0.02 ether}("");
        require(sent);
    }
}