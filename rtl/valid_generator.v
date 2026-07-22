module valid_generator #(
    parameter CYCLES = 5 
)(
    input  wire clock,
    input  wire i_rst,
    input wire i_soft_reset,
    input  wire i_enable,
    
    output reg  i_valid
);

    // Registro interno para llevar la cuenta
    // Se usa 32 bits para soportar retardos muy grandes, pero el sintetizador
    // lo optimizará automáticamente según el valor de CYCLES.
    reg [31:0] counter;

    always @(posedge clock or posedge i_rst) begin
        if (i_rst) begin
            counter <= 0;
            i_valid <= 1'b0;
        end 
        else if (i_soft_reset) begin
            counter <= 0;
            i_valid <= 1'b0;
        end
        else if (i_enable) begin
            // Si el contador llega al límite (CYCLES - 1)
            if (counter == (CYCLES - 1)) begin
                counter <= 0;           // Reiniciamos el contador
                i_valid <= 1'b1;        // mandamos pulso de 1 ciclo
            end 
            else begin
                counter <= counter + 1; // seguimos contando
                i_valid <= 1'b0;        // mantenemos apagado
            end
        end
        else begin
            // Si el módulo general se deshabilita, aseguramos que el valid no se quede "pegado" en 1
            i_valid <= 1'b0; 
        end
    end

endmodule
