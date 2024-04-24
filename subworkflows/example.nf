// TODO: This is purely meant as an example!

include { SOME_METHOD } from './../modules/some_method/main'

process EXAMPLE {
    take:
    some_input

    main:

    SOME_METHOD(
        some_input
    )

    emit:
    result = SOME_METHOD.out.result
}
