module lfsr
    
#(  
    parameter SEED = 16'hFFFF
)
(

    // ---> Inputs
    input wire      i_enable, 
    input wire      i_rst, //reset asincrono
    input wire      i_soft_reset, //reset sincrono
    input wire      clock,

    input wire      i_valid,
    input  wire [15:0] i_seed, //seed dinamica para i_soft_reset

    // ---> Outputs
    output wire o_valid,

    output reg [15:0] LFSR
    
);
    
    
    wire feedback;

    always @(posedge clock or posedge i_rst)
    begin
        // ---> Asignamos shifteando, el valor del 1 va al 2 y asi sucesivamente
        // salvo en los que hayamos seleccionado como realimentados
        //donde se le asigna el valor anterior pero XOR bit de feedback
        if(i_rst)
        begin
            LFSR <= SEED;
        end
        else if (i_soft_reset) begin
            LFSR <= i_seed;
        end
        else if(i_enable && i_valid)
        begin
            LFSR[0] <= feedback;
            LFSR[1] <= LFSR[0];
            LFSR[2] <= LFSR[1] ^ feedback;
            LFSR[3] <= LFSR[2] ^ feedback;
            LFSR[4] <= LFSR[3];
            LFSR[5] <= LFSR[4] ^ feedback;
            LFSR[6] <= LFSR[5];
            LFSR[7] <= LFSR[6];
            LFSR[8] <= LFSR[7];
            LFSR[9] <= LFSR[8];
            LFSR[10] <= LFSR[9];
            LFSR[11] <= LFSR[10];
            LFSR[12] <= LFSR[11];
            LFSR[13] <= LFSR[12];
            LFSR[14] <= LFSR[13];
            LFSR[15] <= LFSR[14];
        end
    end

    assign o_valid = i_valid;
    assign o_lfsr = LFSR;
    assign feedback = LFSR[15];

endmodule
