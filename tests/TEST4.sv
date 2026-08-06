/**
Test de Fronteras (Thresholds)
Verifica que el checker respete los parámetros de LOCK y UNLOCK mediante la inyección paralela de errores.
TEST A : Nunca lockee (Inyectamos menos datos buenos que el LOCK_THR)
    Esto hace que nunca lockee, deberia esperar verse 2 MISMATCH seguidos, (dato corrupto y el que sigue con ancla corrupta) 
    porque al no lockear el checker sigue usando la entrada para predecir el siguiente valor. 

TEST B : Nunca se desbloquee (Inyectamos menos datos malos que el UNLOCK_THR)



*/
initial 
begin
    
    for(i=0; i<30; i=i+1)
    begin
        clock_en = 1;
        
        // -------------------------------------------------------------------------
        // TEST A: NUNCA LOCKEE  (inyectamos menos datos buenos que el LOCK_THR)
        // -------------------------------------------------------------------------

        reset();
        reset_checker();
        i_gen_enable = ENABLE; 
        
        // Abrimos hilos con inyector de errores
        fork
            // Hilo 1:  inyector de errores
            //metemos LOCK_THR-1 datos buenos para que no llegue a lockear
            error_injector(LOCK_THR-1, 1); 
            
            
            // Hilo 2: El monitor principal
            begin
                #($urandom_range(50,500) * 1ns); //dejamos que se generen algunos valids antes de habilitar el checker
                @(posedge clock);
                i_checker_enable = ENABLE; 
                monitor_valids(30, "TEST4-A NUNCA LOCK"); //testeamos 20 datos, deberia ver 2 MISMATCH seguidos y nunca lockear
                // vemos si se lockeo o no
                if (o_lock !== 1'b0) begin
                    $error("[%0t ns] FALLO: El checker se lockeó y no debía.", $time);
                    $finish;
                end else begin
                    $display("[%0t ns] EXITO: El checker soportó la prueba Nunca Lock.", $time);
                end
            end
        join_any
        
        disable fork;
        inject_error = 0; 
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;
    




        #500ns;
        // -------------------------------------------------------------------------
        // TEST B : Nunca se desbloquee (Inyectamos menos datos malos que el UNLOCK_THR)
        // -------------------------------------------------------------------------
        reset();
        reset_checker();
        i_gen_enable = ENABLE; 
        i_checker_enable = ENABLE; 
        
        // Primero dejamos que se lockee 
        // metemos LOCK_THR+1 datos buenos para que lockee
        monitor_valids(LOCK_THR +1 , "TEST4-B NUNCA UNLOCK (Fase de anclaje)"); //LOCK_THR+1 (el primero siempre es MISMATCH)
        
        // Ahora que está en lockeado, empezamos a meter errores 
        fork
            //metemos UNLOCK_THR-1 datos corruptos para que no llegue a deslockearse.
            error_injector(5, UNLOCK_THR-1); // 5 buenos, 2 Corruptos
            begin
                monitor_valids(30, "TEST4-B NUNCA UNLOCK (Fase de inyección de errores)");
                if (o_lock !== 1'b1 ) begin
                    $error("[%0t ns] FALLO: El checker perdió el lock y no debía.", $time);
                    $finish;
                end else begin //else if porque o_lock puede ser X y seguir funcionando, pero no deberia serlo
                    $display("[%0t ns] EXITO: El checker soportó la prueba Nunca Lock.", $time);
                end
            end
        join_any
        
        disable fork;
        inject_error = 0;
        i_checker_enable = DISABLE;
        i_gen_enable = DISABLE;


        
    end

// Si llegamos aca es porque ambos tests pasaron, así que podemos reportar el éxito de la iteración
    $display("\n=======================================================");
    
    $display(" TODOS LOS TESTS DE THRESHOLD PASARON EXITOSAMENTE.");

    $display("=======================================================\n");
    $finish;
end
