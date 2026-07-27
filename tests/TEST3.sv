
integer i = 0; // para iteraciones
integer valid_cnt = 0; //contador de validos 
integer match_cnt = 0; //contador de matches correctos
reg [15:0] expected_lfsr;


// =========================================================
// 2. Tu bloque FOR actualizado
// =========================================================
initial 
begin
    clock_en = 1;
    for(i=0; i<20; i=i+1)
    begin
        $display("\n--- ITERACION %0d ---", i);
        
        reset();
        
        // Inicializamos variables para la iteración actual
        match_cnt = 0;
        valid_cnt = 0;
        i_gen_enable = ENABLE; // Encendemos el generador LFSR
        
        // Esperamos un momento random y habilitamos el checker
        #($urandom_range(50,500) * 1ns);
        
        @(posedge clock);
        i_checker_enable = ENABLE; // prendemos el checker que no se prende al mismo tiempo que el LFSR

        $display("[%0t ns] Checker Habilitado", $time);

        // Definimos cuántos valids queremos monitorear por iteración (ej: 20 valids)
        while (valid_cnt < 20) begin
            @(posedge clock);
            
            // Cada vez que sale un valid, comparamos el valor recibido con el esperado
            if (o_gen_valid) begin 
                valid_cnt = valid_cnt + 1;
                
                // Comparamos el dato recibido con la predicción del checker
                if (o_lfsr == o_checker) begin
                    match_cnt = match_cnt + 1;
                    $display("[%0t ns] Valid #%0d | Recibido: %h | Checker: %h | MATCH    | Matches totales: %0d", 
                                $time, valid_cnt, o_lfsr, o_checker, match_cnt);
                    
                end 
                else begin
                    $display("[%0t ns] Valid #%0d | Recibido: %h | Checker: %h | MISMATCH | Matches totales: %0d", 
                                $time, valid_cnt, o_lfsr, o_checker, match_cnt);
                end
            end
        end
        
        // Apagamos todo antes de la próxima iteración
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;
        $finish; // Finalizamos la simulación después de 100 iteraciones
    end
end
