module top_LSFR
    #(
        parameter SEED = 16'hFFFF,
        parameter CYCLES = 5
    )

    (

        //----> Inputs
        input   wire                    i_enable    ,
        input   wire                    i_rst ,
        input  wire                    i_soft_reset,
        input   wire                    clock,
        
        input  wire [15:0]               i_seed, //seed dinamica para i_soft_reset
           
        // ---> Outputs
        output  wire [15:0] o_LFSR,
        output wire i_valid_monitor


    );
    wire                    i_valid;

    valid_generator #(
        .CYCLES(CYCLES)  
    )
    u_valid_generator
    (
        .clock      (clock      ),
        .i_rst    (i_rst    ),
        .i_enable   (i_enable   ),
        .i_soft_reset(i_soft_reset),
        .i_valid    (i_valid  )
    );


    LSFR#(
        .SEED (SEED)
    )
    u_LSFR
    (
        //----> Outputs
        .LFSR                           (o_LFSR   ),
        //----> Inputs
        .i_enable                       (i_enable  ),
        .i_rst                        (i_rst  ),
        .i_soft_reset                   (i_soft_reset),
        .clock                          (clock    ),
        .i_seed                         (i_seed   ),
        .i_valid                        (i_valid  )
    )                                             ;

    assign i_valid_monitor = i_valid;
endmodule
