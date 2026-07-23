module lfsr_checker #(
    parameter integer LOCK_THR   = 2,
    parameter integer UNLOCK_THR = 5
)(
    //----> Inputs
    input  wire        clock,
    input  wire        i_rst,

    input  wire        i_valid,
    input  wire [15:0] i_lfsr,

    //----> Outputs
    output reg         o_locked
);

    // funcion que calcula el siguiente valor del LFSR a partir del valor pasado como argumento
    function automatic [15:0] lfsr_next;
        input [15:0] prev; // valor anterior del LFSR
        lfsr_next = {prev[14:0], prev[15]} ^ (prev[15] ? 16'h002C : 16'h0000);
    endfunction

    // Codificación de estados
    localparam ST_UNLOCK = 1'b0;
    localparam ST_LOCK   = 1'b1;

    // Registros internos
    reg        state;
    reg [15:0] lfsr_prox;    // valor predicho para la PRÓXIMA palabra recibida
    reg [2:0]  cant_ok;      // cant de matchs consecutivos (estado UNLOCK)
    reg [2:0]  cant_err;     // fallos consecutivos (estado LOCK)
    reg        seeded;       // '1' una vez recibida la primera palabra de anclaje

    
    always @(posedge clock or posedge i_rst) begin
        
        if (i_rst) begin
            state      <= ST_UNLOCK;
            lfsr_prox  <= lfsr_next(SEED);   // pre-calcular primer valor esperado
            cant_ok    <= 3'd0;
            cant_err   <= 3'd0;
            seeded     <= 1'b0;
            o_locked   <= 1'b0;
            o_error    <= 1'b0;
        end 
        
        else
        begin
            o_error <= 1'b0;   // valor por defecto: sin error

            if (i_valid) begin

                case (state)

                    //----------------------------------------------------------------
                    // UNLOCK: Espera LOCK_THR matches consecutivos.
                    ST_UNLOCK: begin
                        if (!seeded) begin
                            // Primera palabra la tomamos como seed, no la contamos como errónea
                            lfsr_prox <= lfsr_next(i_lfsr);
                            cant_ok   <= 3'd0;
                            seeded    <= 1'b1; // flag para comparar la próxima palabra con la predicción 
                        end 
                        
                        else if (i_lfsr == lfsr_prox) begin // si matchea la palabra con la predicción
                            lfsr_prox <= lfsr_next(i_lfsr); // recalculamos el siguiente valor esperado

                            if (cant_ok + 3'd1 >= LOCK_THR[2:0]) begin
                                // Suficientes aciertos consecutivos → LOCK
                                state    <= ST_LOCK;
                                cant_ok  <= 3'd0;
                                cant_err <= 3'd0;
                                o_locked <= 1'b1;
                            end else begin
                                cant_ok  <= cant_ok + 3'd1;
                            end
                        end
                        
                         else begin // no matchea la palabra con la predicción
                            lfsr_prox <= lfsr_next(i_lfsr); // i_lfsr pasa a ser la nueva ancla
                            cant_ok   <= 3'd0;
                        end
                    end


                    //----------------------------------------------------------------
                    // LOCK: Sincronizado con el generador.
                    // Sale a UNLOCK tras UNLOCK_THR fallos consecutivos.
                    ST_LOCK: begin
                        lfsr_prox <= lfsr_next(lfsr_prox);

                        if (i_lfsr == lfsr_prox) begin // si matchea la palabra con la predicción
                            cant_err <= 3'd0;
                        end else begin
                            // Fallo detectado
                            cant_err <= cant_err + 3 me'd1;
                            o_error  <= 1'b1; // Señala error durante este ciclo

                            if (cant_err + 3'd1 >= UNLOCK_THR[2:0]) begin
                                // Demasiados fallos consecutivos → UNLOCK
                                state    <= ST_UNLOCK;
                                cant_err <= 3'd0;
                                cant_ok  <= 3'd0;
                                seeded   <= 1'b0;   // necesita nueva seed
                                o_locked <= 1'b0;
                            end
                        end
                    end

                endcase
                
            end
        end
    end

endmodule
```
