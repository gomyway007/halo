// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Halo is ERC20 {
    uint256 constant private SECONDS_PER_DAY = 24 * 60 * 60;

    uint256 constant private CapInstPre =    25000000;
    uint256 constant private CapInst =       12500000;
    uint256 constant private CapInstA =      12500000;
    uint256 constant private CapFound =      175000000;
    uint256 constant private CapBackup =     50000000;
    uint256 constant private CapTeam =       50000000;
    uint256 constant private CapEcosys =     125000000;
    uint256 constant private CapMarket =     50000000;

    address constant private AddrInstPre = 0x359A36661792195705c5815b3A9b289c87777777;
    address constant private AddrInst = 0x8debeBF42640E422C38c284BDC67a654Be5fd43A;
    address constant private AddrInstA = 0x8b6B71cB9cA0b3D72973958D5Af7E47f05D5EBF8;
    address constant private AddrFound = 0x08EB3f12eD3878E0c6C14250DB04156024D0847d;
    address constant private AddrBackup = 0x81b62984Fd66b795280F311e3F9bb958aAE53BEF;
    address constant private AddrTeam = 0x4eD1Dc5707a4783bA740a482702786C6c631C6Fd;
    address constant private AddrEcosys = 0x153DBdb17C0402B56eEB859a6185694c296d76B7;
    address constant private AddrMarket = 0xA0F930FAF8395DAe70A59d278c64566fCdd11dAF;

    uint256 constant private _mulDecimal = 1e18;
    uint256 constant private  _cap = 500_000_000*_mulDecimal;
    uint256 constant private  _marketMintInit = 8214295;
    uint256 constant private  _marketMintDaily = 714285;

    uint256 immutable private _tegTimestamp;

    mapping(address=>uint256) private _balanceMinted;

    struct DispatchLine{
        uint256 start;
        uint256 end;
        uint256 amount;
    }
    mapping(address=>DispatchLine) private _dispatchLine;

    constructor() ERC20("HALO Token", "HALO") {
        _tegTimestamp = block.timestamp;
        _initTokenMint();
        _initDispatchLine();
    }

    function _initTokenMint() private {
        _mint(AddrBackup,CapBackup * _mulDecimal);
        _mint(AddrMarket,_marketMintInit * _mulDecimal);
    }

    function _initDispatchLine() private {
        _dispatchLine[AddrInstPre] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*150,_tegTimestamp + SECONDS_PER_DAY*1050,CapInstPre * _mulDecimal);
        _dispatchLine[AddrInst] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*60,_tegTimestamp + SECONDS_PER_DAY*960,CapInst * _mulDecimal);
        _dispatchLine[AddrInstA] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*60,_tegTimestamp + SECONDS_PER_DAY*960,CapInstA * _mulDecimal);
        _dispatchLine[AddrFound] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*30,_tegTimestamp + SECONDS_PER_DAY*1830,CapFound * _mulDecimal);
        _dispatchLine[AddrBackup] = DispatchLine(0,0,0);//already minted
        _dispatchLine[AddrTeam] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*330,_tegTimestamp + SECONDS_PER_DAY*1230,CapTeam * _mulDecimal);
        _dispatchLine[AddrEcosys] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*30,_tegTimestamp + SECONDS_PER_DAY*1830,CapEcosys * _mulDecimal);
        _dispatchLine[AddrMarket] = DispatchLine(_tegTimestamp + SECONDS_PER_DAY*30,_tegTimestamp + SECONDS_PER_DAY*1830,(CapMarket - _marketMintInit -_marketMintDaily*12) * _mulDecimal);
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function balanceMintable(address _addr) public view returns(uint256){
        uint256 mintable_;
        uint256 _now = block.timestamp;
        //can not mint
        if(_now <= _tegTimestamp || _dispatchLine[_addr].amount == 0){
            return 0;
        }

        //market amount
        if(_addr == AddrMarket) {
            uint256 passDay = _now - _tegTimestamp < SECONDS_PER_DAY*12?(_now - _tegTimestamp)/SECONDS_PER_DAY:12;
            mintable_ = _marketMintDaily * _mulDecimal * passDay;
        }
   
        //dispatch line amount
        mintable_ += _valueDispatchByLine(_dispatchLine[_addr]);

        //sub minted
        mintable_ -= _balanceMinted[_addr];

        return mintable_;  
    }

    function _valueDispatchByLine(DispatchLine memory dl) private view  returns(uint256){
        uint256 start = dl.start;
        uint256 end = dl.end;
        uint256 amount = dl.amount;

        uint256 ts = block.timestamp;
        if(ts < start) {
            return 0;
        }
        if(ts > end) {
            ts = end;
        }

        return amount * (ts - start)/(end - start);
    }

    function mint(address _addr, uint256 _amount) public {
        uint256 _balanceMintable = balanceMintable(_addr);
        require(_balanceMintable > 0,"nothing to mint");

        uint256 amountMint = _amount > _balanceMintable ? _balanceMintable : _amount;
        _balanceMinted[_addr] += amountMint;
        _mint(_addr,amountMint);
    }
}
