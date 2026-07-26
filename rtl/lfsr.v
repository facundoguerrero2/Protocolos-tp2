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
    output reg o_valid,

    output reg [15:0] o_lfsr
    
);
    
    
    wire feedback;

    always @(posedge clock or posedge i_rst)
    begin
        // ---> Asignamos shifteando, el valor del 1 va al 2 y asi sucesivamente
        // salvo en los que hayamos seleccionado como realimentados
        //donde se le asigna el valor anterior pero XOR bit de feedback
        if(i_rst)
        begin
            o_lfsr <= SEED;
            o_valid <= 1'b0; 
        end
        else if (i_soft_reset) begin
            o_lfsr <= i_seed;
            o_valid <= 1'b0; 
        end
        else if(i_enable && i_valid)
        begin
            o_lfsr[0] <= feedback;
            o_lfsr[1] <= o_lfsr[0];
            o_lfsr[2] <= o_lfsr[1] ^ feedback;
            o_lfsr[3] <= o_lfsr[2] ^ feedback;
            o_lfsr[4] <= o_lfsr[3];
            o_lfsr[5] <= o_lfsr[4] ^ feedback;
            o_lfsr[6] <= o_lfsr[5];
            o_lfsr[7] <= o_lfsr[6];
            o_lfsr[8] <= o_lfsr[7];
            o_lfsr[9] <= o_lfsr[8];
            o_lfsr[10] <= o_lfsr[9];
            o_lfsr[11] <= o_lfsr[10];
            o_lfsr[12] <= o_lfsr[11];
            o_lfsr[13] <= o_lfsr[12];
            o_lfsr[14] <= o_lfsr[13];
            o_lfsr[15] <= o_lfsr[14];
            
            // valid
            o_valid <= i_valid;
        end
        else 
        begin
            o_valid <= 1'b0;
        end
    end
    assign feedback = o_lfsr[15];

endmodule
