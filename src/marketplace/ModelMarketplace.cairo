use starknet::ContractAddress;

#[starknet::interface]
trait IModelMarketPlace<TContractState> {
    fn register_model(ref self: TContractState, owner: ContractAddress);
    fn split(self: @TContractState, model_id: u128, amount: u256, token_address: ContractAddress);
}


#[starknet::contract]
mod ModelMarketPlace {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::token::erc20::interface::{IERC20CamelDispatcher, IERC20CamelDispatcherTrait};

    #[storage]
    struct Storage {
        ml_village: ContractAddress,
        model_owner: LegacyMap<u128, ContractAddress>,
        model_count: u128
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ModelSold: ModelSold,
    }

    #[derive(Drop, starknet::Event)]
    struct ModelSold {
        #[key]
        model_id: u128,
        amount: u256
    }

    #[constructor]
    fn constructor(ref self: ContractState, ml_village: ContractAddress) {
        self.ml_village.write(ml_village);
    }

    #[external(v0)]
    impl ModelMarketPlace of super::IModelMarketPlace<ContractState> {
        fn register_model(ref self: ContractState, owner: ContractAddress) {
            let new_count = self.model_count.read() + 1;
            self.model_owner.write(new_count, owner);
            self.model_count.write(new_count);
        }

        fn split(
            self: @ContractState, model_id: u128, amount: u256, token_address: ContractAddress
        ) {
            let fee = amount / 10;
            let net_amount = amount - fee;
            let caller = get_caller_address();
            IERC20CamelDispatcher { contract_address: token_address }
                .transferFrom(caller, self.ml_village.read(), fee);
            IERC20CamelDispatcher { contract_address: token_address }
                .transferFrom(caller, self.model_owner.read(model_id), net_amount);
        }
    }
}
