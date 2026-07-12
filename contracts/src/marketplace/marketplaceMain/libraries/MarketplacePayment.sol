
import {IMarketplaceRegistry} from "../interfaces/IMarketplaceRegistry.sol";
import {IMarketplacePayment} from "../interfaces/IMarketplacePayment.sol";


contract MarketplacePayment is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable
{
    IMarketplaceRegistry internal _registry;

    uint256[49] private __gap;
}