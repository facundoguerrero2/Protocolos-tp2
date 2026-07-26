module lfsr_checker #(
    parameter integer LOCK_THR   = 2,
    parameter integer UNLOCK_THR = 5
)(
    //----> Inputs
    input  wire        clock,
    input  wire        i_rst,
    input wire       i_enable,

    input  wire        i_valid,
    input  wire [15:0] i_lfsr,

    //----> Outputs
    output reg                  o_lock,
    output wire [15:0]         o_checker
);

    // funcion que calcula el siguiente valor del lfsr a partir del valor pasado como argumento
    function automatic [15:0] lfsr_next;
        input [15:0] prev; // valor anterior del lfsr
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

    
    always @(posedge clock or posedge i_rst) begin          //always * en general, para las maquinas de estado REVISARLO y maquina de estado centralizada solo en triggerear 
        
        if (i_rst) begin
            state      <= ST_UNLOCK;
            lfsr_prox  <= lfsr_next(SEED);   // pre-calcular primer valor esperado
            cant_ok    <= 3'd0;
            cant_err   <= 3'd0;
            o_lock     <= 1'b0;
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
                        if (i_lfsr == lfsr_prox) begin // si matchea la palabra con la predicción

                            lfsr_prox <= lfsr_next(lfsr_prox); // recalculamos el siguiente valor esperado
                            
                            if (cant_ok + 3'd1 >= LOCK_THR) begin
                                // Suficientes aciertos consecutivos → LOCK
                                state    <= ST_LOCK;
                                cant_ok  <= 3'd0;
                                cant_err <= 3'd0;
                                o_lock <= 1'b1;
                            end else begin
                                cant_ok  <= cant_ok + 3'd1;
                            end
                        end
                        
                         else begin // no matchea la palabra con la predicción
                            lfsr_prox <= lfsr_next(i_lfsr); // i_lfsr pasa a ser el nuevo ancla
                            cant_ok   <= 3'd0;
                        end
                    end


                    //----------------------------------------------------------------
                    // LOCK: Sincronizado con el generador.
                    // Sale a UNLOCK tras UNLOCK_THR fallos consecutivos.
                    ST_LOCK: begin
                        lfsr_prox <= lfsr_next(lfsr_prox); //calculo la siguiente palabra esperada pero con el valor anterior de lfsr_prox, no con el valor recibido por i_lfsr

                        if (i_lfsr == lfsr_prox) begin // si matchea la palabra con la predicción
                            cant_err <= 3'd0;
                        end
                        
                        else    // Fallo detectado
                        begin    
                            
                            cant_err <= cant_err + 3 me'd1;
                            //o_error  <= 1'b1; // Señala error durante este ciclo
                            
                            if (cant_err + 3'd1 >= UNLOCK_THR)   // Demasiados fallos consecutivos → UNLOCK
                            begin
                                state    <= ST_UNLOCK;
                                cant_err <= 3'd0;
                                cant_ok  <= 3'd0;
                                seeded   <= 1'b0;   // necesita nueva seed
                                o_lock <= 1'b0;
                            end
                        end
                    end

                endcase

            end
        end
    end

    assign o_checker = lfsr_prox;

endmodule
```


//TEST
// agregar pipes random en eltb entre la coneaxion del generador y el checker 
// registrando el dato y el valid  

// restear en momentos random el generador 
// contador de lockeos y deslockeos para saber cuantas veces se lockeo y deslockeo el checker

//testear los thresholds
//mandar 2 bien uno mal y asi y ver que nunca se lockea                     ver corruptor de bits
// y al reves tambien

//usar delays random pushback popfront
