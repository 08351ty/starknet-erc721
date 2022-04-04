%lang starknet
%builtins pedersen range_check ecdsa

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_eq
)
from starkware.starknet.common.syscalls import (get_contract_address, get_caller_address)

from contracts.token.ERC721.ERC721_base import (
    ERC721_name, ERC721_symbol, ERC721_balanceOf, ERC721_ownerOf, ERC721_getApproved,
    ERC721_isApprovedForAll, ERC721_mint, ERC721_burn, ERC721_initializer, ERC721_approve,
    ERC721_setApprovalForAll, ERC721_transferFrom, ERC721_safeTransferFrom)

#
# Constructor
#

#
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(name: felt, 
    symbol: felt, 
    owner: felt,
    legs: felt,
    sex: felt,
    wings: felt
    ):
    ERC721_initializer(name, symbol)
    let to = owner
    let token_id: Uint256 = Uint256(1,0)
    ERC721_mint(to, token_id)

    #assign attributes
    assign_attributes(token_id, legs, sex, wings)
    current_token_id_storage.write(token_id)
    return ()
end

@storage_var
func assigned_legs_number(token_id: Uint256) -> (legs: felt):
end

@storage_var
func assigned_sex_number(token_id: Uint256) -> (legs: felt):
end

@storage_var
func assigned_wings_number(token_id: Uint256) -> (legs: felt):
end

#tracks how many NFTs minted
@storage_var
func current_token_id_storage() -> (token_id: Uint256):
end


#
# Getters
#

@view
func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
    let (name) = ERC721_name()
    return (name)
end

@view
func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (symbol : felt):
    let (symbol) = ERC721_symbol()
    return (symbol)
end

@view
func balanceOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt) -> (
        balance : Uint256):
    let (balance : Uint256) = ERC721_balanceOf(owner)
    return (balance)
end

@view
func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (owner : felt):
    let (owner : felt) = ERC721_ownerOf(token_id)
    return (owner)
end

@view
func getApproved{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256) -> (approved : felt):
    let (approved : felt) = ERC721_getApproved(token_id)
    return (approved)
end

@view
func isApprovedForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, operator : felt) -> (is_approved : felt):
    let (is_approved : felt) = ERC721_isApprovedForAll(owner, operator)
    return (is_approved)
end

@view
func token_of_owner_by_index{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account:felt, index:felt) -> (token_id: Uint256):
    # gets the token_id given account and index
    let token_id: Uint256 = token_id_of_account_index.read(account, index)
    return (token_id)
end

@view
func get_animal_characteristics{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> (sex: felt, legs: felt, wings: felt):
    let sex: felt = assigned_sex_number.read(token_id)
    let legs: felt = assigned_legs_number.read(token_id)
    let wings: felt = assigned_wings_number.read(token_id)
    return (sex, legs, wings)
end

#
# Externals
#

@external
func declare_animal{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(sex: felt, legs: felt, wings: felt) -> (token_id: Uint256):
    alloc_locals
    let (caller) = get_caller_address()
    # increments the current_token_id storage var
    let token_id: Uint256 = next_token_id()

    # mints an ERC721
    ERC721_mint(caller, token_id)

    # assign characteristics
    assign_attributes(token_id, legs, sex, wings)

    return (token_id)

end

@external
func declare_dead_animal{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256) -> ():
    let (caller) = get_caller_address()

    # make sure "caller" actually owns the token_id
    assert ERC721_ownerOf(token_id) = caller

    # dead animals have 0 attributes, changing that and burning
    assign_attributes(token_id, 0, 0, 0)
    ERC721_burn(token_id)




    return ()
end

@external
func approve{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }(to: felt, token_id: Uint256):
    ERC721_approve(to, token_id)
    return ()
end

@external
func setApprovalForAll{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        operator : felt, approved : felt):
    ERC721_setApprovalForAll(operator, approved)
    return ()
end

@external
func transferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256):
    ERC721_transferFrom(_from, to, token_id)
    return ()
end

@external
func safeTransferFrom{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}(
        _from : felt, to : felt, token_id : Uint256, data_len : felt, data : felt*):
    ERC721_safeTransferFrom(_from, to, token_id, data_len, data)
    return ()
end

# increments to the next token id
func next_token_id{
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    }() -> (next_token_id: Uint256):
    let (current_token_id) = current_token_id_storage.read()
    let next_token_id: Uint256 = uint256_add(current_token_id, Uint256(1,0))
    current_token_id_storage.write(next_token_id)
    return (next_token_id)
end

func add_token_to_owner{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt, index: felt) -> (token_id: Uint256):


    # increment number of tokens owned by owner
    let (tokens) = num_tokens_for_certain_owner.read(account)
    num_tokens_for_certain_owner.write(account, tokens + 1)
    return (tokens)
end

func assign_attributes{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(token_id: Uint256, legs: felt, sex: felt, wings: felt) ->():
    assigned_legs_number.write(token_id, legs)
    assigned_sex_number.write(token_id, sex)
    assigned_wings_number.write(token_id, wings)
end




# @external
# func mint{
#         pedersen_ptr: HashBuiltin*,
#         syscall_ptr: felt*,
#         range_check_ptr
#     }(to: felt, token_id: Uint256):
#     #Ownable_only_owner()
#     ERC721_mint(to, token_id)
#     return ()
# end

# @external
# func burn{
#         pedersen_ptr: HashBuiltin*,
#         syscall_ptr: felt*,
#         range_check_ptr
#     }(token_id: Uint256):
#     #Ownable_only_owner()
#     ERC721_burn(token_id)
#     return ()
# end

