    reg tb_valid; 


    // =========================================================================
// =========================================================================
    // Parámetros y registros del generador de valid
    // =========================================================================
    parameter MIN_WAIT = 1;  // Mínima cantidad de ciclos a esperar
    parameter MAX_WAIT = 10; // Máxima cantidad de ciclos a esperar
    parameter DEFAULT_WAIT_CYCLES = 1;
    reg [31:0] wait_cycles = 1;  // Variable que guarda el tiempo de espera actual
    reg random_cycles
    reg [31:0] counter;      // Contador de ciclos
    reg tb_valid;            // Tu señal para conectar al módulo

    // =========================================================================
    // Generador de 'valid' con espera aleatoria (Testbench)
    // =========================================================================
    always @(posedge clock) begin
        if (rst) begin
            tb_valid <= 1'b0;
            counter <= 0;
        end 
        else begin
            // Si el contador alcanzó el límite aleatorio que estábamos esperando
            if (counter == wait_cycles) begin
                tb_valid <= 1'b1;       // 1. Mandamos el pulso
                counter <= 0;           // 2. Reiniciamos el contador

                // 3. Acá está la magia: "desde otro lado" (para la próxima vuelta)
                // calculamos un NUEVO límite aleatorio usando los parámetros.
                if (random_cycles == 1)
                begin 
                    wait_cycles <= $urandom_range(MIN_WAIT, MAX_WAIT);
                end
                else 
                    wait_cycles <= DEFAULT_WAIT_CYCLES
            end 
            else begin
                // Mientras no lleguemos, mantenemos en 0 y seguimos contando
                tb_valid <= 1'b0;
                counter <= counter + 1;
            end
        end
    end

endmodule