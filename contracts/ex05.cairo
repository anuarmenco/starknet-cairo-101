// ######## Ex 05
// Variables Público/Privadas
// En este ejercicio, tú necesitas:
// - Usa una función para asignar una variable privada
// - Usa una función para duplicar esa función en una variable pública
// - Usa una función para mostrarte el valor correcto de una variable privada
// - Tus puntos son acreditados por el contrato

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from contracts.utils.ex00_base import (
    tderc20_address,
    has_validated_exercise,
    distribute_points,
    validate_exercise,
    ex_initializer,
)

//
// Declarando variables en memoria o variables de estado (storage_var)
// Las variables en memoria (Storage vars) NO son por defecto, o de manera predeterminada, visibles en el ABI.
// Las variables en memoria son similares a las variables del tipo "private" en Solidity
//

// Necesitas leer los valores en esos espacios de almacenamiento (storage slots). ¡Pero no todos tienen getters!

@storage_var
func user_slots_storage(account: felt) -> (user_slots_storage: felt) {
}

@storage_var
func user_values_public_storage(account: felt) -> (user_values_public_storage: felt) {
}

@storage_var
func values_mapped_secret_storage(slot: felt) -> (values_mapped_secret_storage: felt) {
}

@storage_var
func was_initialized() -> (was_initialized: felt) {
}

@storage_var
func next_slot() -> (next_slot: felt) {
}

//
// Declarando getters
// Variables de tipo públicas deben ser declaradas explicitamente con un getter
//

@view
func user_slots{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(account: felt) -> (
    user_slot: felt
) {
    let (user_slot) = user_slots_storage.read(account);
    return (user_slot,);
}

@view
func user_values{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    account: felt
) -> (user_value: felt) {
    let (value) = user_values_public_storage.read(account);
    return (value,);
}

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _tderc20_address: felt, _players_registry: felt, _workshop_id: felt, _exercise_id: felt
) {
    ex_initializer(_tderc20_address, _players_registry, _workshop_id, _exercise_id);
    return ();
}

//
// Funciones externas
//

@external
func claim_points{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    expected_value: felt
) {
    // Leyendo la dirección de quien llama o del emisor
    let (sender_address) = get_caller_address();

    with_attr error_message("User slot not assigned. Call assign_user_slot") {
        // Verificando que el usuario tenga un espacio de almacenamiento (slot) asignado
        let (user_slot) = user_slots_storage.read(sender_address);
        assert_not_zero(user_slot);
    }

    // Verificando que el valor aportado por el usuario es el valor esperado
    // Sigo astuto.
    let (value) = values_mapped_secret_storage.read(user_slot);
    with_attr error_message("Input value is not the expected secret value") {
        assert value = expected_value + 23;
    }

    // Verificando si el usuario ha validado el ejercicio antes
    validate_exercise(sender_address);
    // Enviando puntos a la dirección especificada como parametro
    distribute_points(sender_address, 2);
    return ();
}

@external
func assign_user_slot{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Leyendo la dirección del emisor o de quien llama la función
    let (sender_address) = get_caller_address();
    let (next_slot_temp) = next_slot.read();
    let (next_value) = values_mapped_secret_storage.read(next_slot_temp + 1);
    if (next_value == 0) {
        user_slots_storage.write(sender_address, 1);
        next_slot.write(0);
    } else {
        user_slots_storage.write(sender_address, next_slot_temp + 1);
        next_slot.write(next_slot_temp + 1);
    }
    return ();
}

@external
func copy_secret_value_to_readable_mapping{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    // Leyendo la dirección del emisor o de quien llama la función
    let (sender_address) = get_caller_address();

    with_attr error_message("User slot not assigned. Call assign_user_slot") {
        // Verificando que el usuario tenga un espacio de almacenamiento (slot) asignado
        let (user_slot) = user_slots_storage.read(sender_address);
        assert_not_zero(user_slot);
    }
    // Leyendo el valor secreto del usuario
    let (secret_value) = values_mapped_secret_storage.read(user_slot);

    // Copiar el valor de values_mapped_secret_storage no accesible a
    user_values_public_storage.write(sender_address, secret_value - 23);
    return ();
}

//
// Funciones externas - Administración
// Solo los administradores pueden llamarlas. No necesitas entenderlas para terminar el ejercicio
//

@external
func set_random_values{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    values_len: felt, values: felt*
) {
    // Verifica si los valores aleatorios ya fueron inicializados
    let (was_initialized_read) = was_initialized.read();
    with_attr error_message("random values already initialized") {
        assert was_initialized_read = 0;
    }
    // Guardando los valores dados en la variable de estado
    set_a_random_value(values_len, values);

    // Marcar que el valor guardado fue inicializado
    was_initialized.write(1);
    return ();
}

func set_a_random_value{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    values_len: felt, values: felt*
) {
    if (values_len == 0) {
        // Inicia con sum=0.
        return ();
    }

    set_a_random_value(values_len=values_len - 1, values=values + 1);
    values_mapped_secret_storage.write(values_len - 1, [values]);

    return ();
}
