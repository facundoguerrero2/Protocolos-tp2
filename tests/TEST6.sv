/**
TEST 6: Resiliencia ante Resets randoms
Verifica que el sistema pueda recuperarse y volver a lockearse 
si se le aplica un reset repentino en pleno funcionamiento.
*/
initial 
begin
    
    for(i=0; i<50; i=i+1)
    begin
        clock_en = 1;
        
        $display("\n=======================================================");
        $display(" TEST 6: RESETS ASESINOS | ITERACION %0d" , i);
        $display("=======================================================");

        // 1. Arranque normal
        reset(); 
        reset_checker();
        i_gen_enable = ENABLE; 
        i_checker_enable = ENABLE; 
        
        fork
            // ---------------------------------------------------------
            // Hilo Espia: Monitoreo continuo
            // ---------------------------------------------------------
            begin : hilo_monitor
                monitor_valids(100000, "TEST 6: RESETS ASESINOS");
            end

            // ---------------------------------------------------------
            // Hilo Principal: Secuencia del test
            // ---------------------------------------------------------
            begin : hilo_secuencia
                // Esperamos a que el sistema se lockee normalmente
                wait(o_lock == 1'b1);
                $display("[%0t ns] Sistema lockeado. Operando con normalidad...", $time);
                
                // Lo dejamos funcionar un rato aleatorio mientras está lockeado
                #($urandom_range(50, 500) * 1ns);
                
                // ---------------------------------------------------------
                // 2. INYECTAMOS EL RESET
                // ---------------------------------------------------------
                $display("[%0t ns] ---> INYECTANDO RESET", $time);
                
                fork
                    begin
                        // Hilo A: resetea checker (que mantiene el reset por 1us-249us y luego lo baja)
                        reset_checker(); 
                    end
                    begin
                        // Hilo B: Le damos 1 nanosegundo al simulador para que procese la acción de reset y verificamos que el Lock haya caído.
                        #1;
                        if (o_lock !== 1'b0) begin
                            $error("[%0t ns] FALLO CRITICO: El reset no bajó la señal de Lock.", $time);
                            $finish;
                        end
                        $display("[%0t ns] Deslockeado con éxito. El checker reaccionó al reset.", $time);
                    end
                join // Join porque queremos que espere a reset_checker()
                
                // ---------------------------------------------------------
                // 3. RECUPERACIÓN
                // ---------------------------------------------------------
                $display("[%0t ns] Reset liberado. Esperando que el sistema se recupere por sí solo...", $time);
                
                // Esperamos que vuelva a lockear, pero con un timeout de seguridad
                fork : hilo_timeout
                    begin
                        wait(o_lock == 1'b1);
                        $display("[%0t ns] EXITO: El sistema sobrevivió al reset y volvió a lockearse.", $time);
                    end
                    begin
                        #50000ns; // Timeout
                        $error("[%0t ns] FALLO: El sistema nunca se recuperó del reset asesino.", $time);
                        $finish;
                    end
                join_any
                
                // Matamos el hilo del timeout apenas logre lockear
                disable hilo_timeout; 
                
                // Retardo adicional operativo para observar el comportamiento en LOCK antes de finalizar
                #($urandom_range(50, 100) * 1ns);
            end
        join_any
        
        // Finaliza la iteración principal, se detiene el monitoreo continuo
        disable hilo_monitor;
        
        // Limpieza final de la iteración
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;
        #500ns;
    end

    $display("\n=======================================================");
    $display(" EL TEST 6 (RESETS RANDOMS) PASO EXITOSAMENTE.");
    $display("=======================================================\n");
    $finish;
end
