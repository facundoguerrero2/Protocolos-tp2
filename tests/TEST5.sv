/**
Test de LOCK/UNLOCK (PING-PONG)
Verifica que el checker cambie constantemente de estado LOCK a UNLOCK y viceversa, 
mediante la inyección de errores controlados forzando su entrada y salida de los estados.

VUELTA = LOCKEAR Y DESLOCKEAR
*/



// cuantos datos toma hacer un ciclo completo de Lock y Unlock
localparam VALIDS_POR_VUELTA = (LOCK_THR +1) + UNLOCK_THR; 

// Cantidad de ciclos que queremos monitorear (ciclos completos de Lock y Unlock)
localparam CANT_VUELTAS = 20;
localparam TRANSICIONES_ESPERADAS = CANT_VUELTAS * 2;
localparam VALIDS_A_MONITOREAR = VALIDS_POR_VUELTA * (CANT_VUELTAS); 



initial 
begin
    
    for(i=0; i<10; i=i+1)
    begin
        clock_en = 1;
        
        $display("\n=======================================================");
        $display(" TEST 5:(TOGGLE LOCK/UNLOCK) | ITERACION %0d" , i);
        $display("=======================================================");

        reset();
        reset_checker();
        i_gen_enable = ENABLE; 
        lock_cnt = 0;
        unlock_cnt = 0;
        
        fork
            // ---------------------------------------------------------
            // Hilo 1: Inyector de errores agresivo
            // Inyecta suficientes buenos para Lockear, y suficientes malos para Deslockear
            // ---------------------------------------------------------
            begin
                error_injector(LOCK_THR + 1 , UNLOCK_THR); //LOCK:TH +1 porque en el arranque el checker no tiene ancla, entonces el primer dato bueno no cuenta para lockear.
            end
                        
            // ---------------------------------------------------------
            // Hilo 3: El monitor principal 
            // ---------------------------------------------------------
            begin
    
                
                // --- EJECUCIÓN ---
                #($urandom_range(50,200) * 1ns); // Espera aleatoria inicial
                @(posedge clock);
                i_checker_enable = ENABLE; 
                
                // Evaluamos exactamente la cantidad que calculamos
                monitor_valids(VALIDS_A_MONITOREAR, "TEST5 FASE DE PING-PONG"); 
                
                // Verificamos si logró hacer las transiciones
                #1;
                if ((lock_cnt + unlock_cnt) != TRANSICIONES_ESPERADAS) begin
                    $error("[%0t ns] FALLO: El checker no transicionó lo suficiente. Transiciones = %0d de %0d esperadas", 
                            $time, (lock_cnt + unlock_cnt), TRANSICIONES_ESPERADAS);
                    $finish;
                end else begin
                    $display("[%0t ns] EXITO: El checker hizo ping-pong perfectamente (%0d transiciones).", 
                            $time, (lock_cnt + unlock_cnt));
                end
            end

        join_any
        
        
        disable fork;
        inject_error = 0; 
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;
        
        
    end

    // Si llegamos aca es porque pasaron todas las iteraciones
    $display("\n=======================================================");
    $display(" EL TEST 5 (PING-PONG) PASO EXITOSAMENTE EN TODAS LAS ITERACIONES.");
    $display("=======================================================\n");
    $finish;
end


            