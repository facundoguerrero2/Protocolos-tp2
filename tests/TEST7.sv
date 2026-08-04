/**
TEST 7: Cambio Dinámico de Semilla 
Verifica que el checker pueda re lockearse si el los datos generados por el generador cambian abruptamente a una secuencia distinta por un cambio de semilla y reset.
*/
initial 
begin
    
    for(i=0; i<100; i=i+1)
    begin
        clock_en = 1;
        
        $display("\n=======================================================");
        $display(" TEST 7: CAMBIO DE SEMILLA | ITERACION %0d" , i);
        $display("=======================================================");

        // 1. Arranque normal
        reset(); 
        reset_checker();
        i_gen_enable = ENABLE; 
        i_checker_enable = ENABLE; 
        
        fork
            // ---------------------------------------------------------
            // Hilo Espía: Monitoreo continuo
            // ---------------------------------------------------------
            begin : hilo_monitor
                monitor_valids(100000, "TEST 7: CAMBIO DE SEMILLA");
            end

            // ---------------------------------------------------------
            // Hilo Principal: Secuencia del test
            // ---------------------------------------------------------
            begin : hilo_secuencia
                
                // Esperamos a que el sistema se lockee normalmente
                $display("\n[%0t ns] ---> FASE DE ANCLAJE", $time);
                wait(o_lock == 1'b1);
                
                // Lo dejamos operar un rato random
                #($urandom_range(200, 500) * 1ns);
                
                // ---------------------------------------------------------
                // 2. CAMBIAMOS LA SEMILLA 
                // ---------------------------------------------------------
                $display("\n[%0t ns] ---> ACCION: Cambio de semilla", $time);
                
                //cambiamos la seed con las tasks que ya teniamos para eso      
                set_seed();
                @(posedge clock);
                #1;
                soft_reset();
                
                // ---------------------------------------------------------
                // 3. RECUPERACIÓN
                // ---------------------------------------------------------
                // Al cambiar la semilla, el checker empezará a ver datos que no coinciden deberia deslockearse y volverse a lockear solo
                
                wait(o_lock == 1'b0); //esperamos que se desloquee
                
                //esperamos que vuelva a lockear con timeout de resguardo
                fork : hilo_timeout
                    begin
                        wait(o_lock == 1'b1);
                        $display("\n[%0t ns] ---> EXITO: El sistema se volvio a lockear con el cambio de semilla.", $time);
                    end
                    begin
                        #50000ns; // Timeout
                        $error("\n[%0t ns] FALLO: El sistema no logro lockearse despues del cambio de semilla.", $time);
                        $finish;
                    end
                join_any
                
                // Matamos el hilo del timeout apenas logre lockear
                disable hilo_timeout; 
                
                // Retardo adicional para ver los MATCH perfectos con la nueva secuencia
                #($urandom_range(100, 300) * 1ns);
            end
        join_any
        
        // Finaliza la iteración principal, matamos al espía
        disable hilo_monitor;
        
        // Limpieza final de la iteración
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;
        #500ns;
    end

    $display("\n=======================================================");
    $display(" EL TEST 7 (CAMBIO DE SEMILLA) PASÓ EXITOSAMENTE.");
    $display("=======================================================\n");
    $finish;
end
