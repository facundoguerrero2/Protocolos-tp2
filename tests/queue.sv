
reg        inject_error;


// Declaración de Queue 
// El símbolo [$] indica que es de tamaño dinámico
reg [15:0] delay_queue [$]; 
// --- Señales que irán conectadas a los inputs del Checker ---
reg [15:0] queue_data_out;
reg        queue_valid_out;

always @(posedge clock) begin
    if (i_rst) begin
        delay_queue.delete(); // Vaciamos la cola al resetear
        queue_valid_out <= 1'b0;
    end else begin
    
        // ----------------------------------------------------
        // 1. ESCRITURA EN LA COLA (PUSH) - Lado del Generador
        // ----------------------------------------------------
        if (o_gen_valid) begin //gracias a este if tendremos guardados solo datos validos en la cola
            // Si además queremos inyectar un error, lo hacemos aca
            if (inject_error)
                delay_queue.push_back(o_lfsr ^ 16'h0001); // Inyectar error
            else
                delay_queue.push_back(o_lfsr); // Dato sano
        end
        
        
        
        // ----------------------------------------------------
        // 2. LECTURA DE LA COLA (POP) - Lado del Checker
        // ----------------------------------------------------

        // delay_queue.size() nos dice cuántos elementos hay guardados.
        // $urandom_range(1, 100) <= 30) es un "sorteo" para decidir si sacamos un dato o no (30% de probabilidad) esto mete delay 
        // de cantidad de ciclos aleatorios que le tome ganar el sorteo.
        if (i_checker_enable && delay_queue.size() > 0 && ($urandom_range(1, 100) <= 30)) begin 
            // Hay datos y ganamos el sorteo
            queue_data_out  <= delay_queue.pop_front(); // Sacamos el más viejo
            queue_valid_out <= 1'b1;                    // Le avisamos al checker que hay dato
        end else begin
            // La cola está vacía, o simplemente "decidimos" retener el dato este ciclo
            queue_valid_out <= 1'b0;
        end
    end
end

