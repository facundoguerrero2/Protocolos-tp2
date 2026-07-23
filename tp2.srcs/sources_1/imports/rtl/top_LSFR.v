module top_LSFR
    #(
        parameter SEED = 16'hFFFF,
        parameter CYCLES = 5
    )

    (

        //----> Inputs
        input   wire                    i_enable    ,
        input   wire                    i_rst ,
        input   wire                    i_soft_reset,
        input   wire                    clock,
        
        input  wire [15:0]              i_seed, //seed dinamica para i_soft_reset
        input  wire                     i_valid,
           
        // ---> Outputs
        output  wire [15:0] o_LFSR,
        output wire o_valid

    );

    

    LSFR#(
        .SEED (SEED)
    )
    u_LSFR
    (
        //----> Outputs
        .LFSR                           (o_LFSR   ),
        .o_valid                        (o_valid  ),
        //----> Inputs
        .i_enable                       (i_enable  ),
        .i_rst                          (i_rst  ),
        .i_soft_reset                   (i_soft_reset),
        .clock                          (clock    ),
        .i_seed                         (i_seed   ),
        .i_valid                        (i_valid)
    )                                             ;

endmodule
