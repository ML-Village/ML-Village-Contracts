use starknet::{ContractAddress};
use alexandria_storage::list::{List, ListTrait};

#[starknet::interface]
trait IRegistryFunction<TContractState> {
    fn register_model(ref self: TContractState, model_id: u128);
    fn register_subscription(
        ref self: TContractState,
        owner_address: ContractAddress,
        model_id: u128,
        subscription_end_timestamp: felt252
    );
    fn check_subscription(
        ref self: TContractState,
        owner_address: ContractAddress,
        model_id: u128,
        subscription_end_timestamp: felt252
    ) -> Option<RegisteredSubscription>;
    fn get_all_model(ref self: TContractState,) -> Array<u128>;
}

#[derive(Copy, Drop, starknet::Store, Serde, PartialEq)]
struct RegisteredSubscription {
    owner_address: ContractAddress,
    model_id: u128,
    subscription_end_timestamp: felt252
}

mod Error {
    const MODEL_NOT_REGISTERED: felt252 = 'Model is not registered';
}


#[starknet::contract]
mod Registry {
    //Imports in Contract 
    use core::option::OptionTrait;
    use core::serde::Serde;
    use core::array::ArrayTrait;
    use core::traits::Into;
    use starknet::{ContractAddress};
    use super::RegisteredSubscription;
    use super::Error::MODEL_NOT_REGISTERED;
    use alexandria_storage::list::{List, ListTrait};

    //Storage Variable
    #[storage]
    struct Storage {
        owner: ContractAddress,
        registeredModel: List<u128>,
        registeredSubscription: LegacyMap<ContractAddress, List<RegisteredSubscription>>,
    }
    //Constructor
    #[constructor]
    fn constructor(ref self: ContractState, initial_owner: ContractAddress) {
        self.owner.write(initial_owner);
    }
    #[external(v0)]
    impl Registry of super::IRegistryFunction<ContractState> {
        fn register_model(ref self: ContractState, model_id: u128) {
            let mut current_array = self.registeredModel.read();
            current_array.append(model_id);
        }

        fn register_subscription(
            ref self: ContractState,
            owner_address: ContractAddress,
            model_id: u128,
            subscription_end_timestamp: felt252
        ) {
            let models = self.registeredModel.read();
            let mut intials = 0;
            let result = loop {
                if models.len() == intials {
                    break false;
                }
                if models.get(intials).unwrap() == model_id {
                    break true;
                }
                intials += 1;
            };
            if result == false {
                panic(array![MODEL_NOT_REGISTERED]);
            }

            let mut current_array = self.registeredSubscription.read(owner_address);
            current_array
                .append(
                    RegisteredSubscription {
                        owner_address: owner_address,
                        model_id: model_id,
                        subscription_end_timestamp: subscription_end_timestamp
                    }
                );
            self.registeredSubscription.write(owner_address, current_array);
        }
        fn check_subscription(
            ref self: ContractState,
            owner_address: ContractAddress,
            model_id: u128,
            subscription_end_timestamp: felt252
        ) -> Option<RegisteredSubscription> {
            let check_subs = RegisteredSubscription {
                owner_address: owner_address,
                model_id: model_id,
                subscription_end_timestamp: subscription_end_timestamp
            };
            let current_array = self.registeredSubscription.read(owner_address);
            let mut found = false;
            let mut intial = 0;
            loop {
                if intial == current_array.len() {
                    break Option::None;
                };
                if current_array.get(intial).unwrap() == check_subs {
                    found = true;
                    break Option::Some(check_subs);
                }
                intial += 1;
            }
        }
        fn get_all_model(ref self: ContractState) -> Array<u128> {
            let mut models = self.registeredModel.read();
            let mut result = ArrayTrait::<u128>::new();
            let mut intial = 0;
            loop {
                if models.len() == 0 {
                    break @result;
                }
                if models.len() == result.len() {
                    break @result;
                }
                result.append(models.get(intial).unwrap());
                intial += 1;
            };
            result
        }
    }
}
