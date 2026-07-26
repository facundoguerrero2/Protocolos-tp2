
    always @(posedge clock) begin
        if (i_rst) begin
            
            valid_signal <= 1'b0;
            valid_cicle_counter <= 0;

            if (valid_random_cycles == 1)
                begin   
                    valid_wait_cycles <= $urandom_range(MIN_WAIT, MAX_WAIT);
                end
            else begin 
                valid_wait_cycles <= DEFAULT_WAIT_CYCLES;
            end

        end 


        else if (i_soft_reset) begin
            valid_signal <= 1'b0;
            valid_cicle_counter <= 0;

            if (valid_random_cycles == 1)
                begin   
                    valid_wait_cycles <= $urandom_range(MIN_WAIT, MAX_WAIT);
                end
            else begin 
                valid_wait_cycles <= DEFAULT_WAIT_CYCLES;
            end

        end

        else begin
            // si el contador alcanzo el límite aleatorio que estábamos esperando
            if (valid_cicle_counter == valid_wait_cycles) 
            begin
                
                if(valid_signal == 1'b1) begin
                    valid_signal <= 1'b0; // 1. Apagamos el pulso
                end
                else begin
                    valid_signal <= 1'b1; // 2. Mandamos el pulso
                end
                valid_cicle_counter <= 0;           // 2. Reiniciamos el contador

                //seteamos el limite aleatorio para el próximo pulso
                if (valid_random_cycles == 1)
                begin   
                    valid_wait_cycles <= $urandom_range(MIN_WAIT, MAX_WAIT);
                end
                else begin
                    valid_wait_cycles <= DEFAULT_WAIT_CYCLES;
                end
            end 
            else begin
                valid_cicle_counter <= valid_cicle_counter + 1;
            end
        end
    end


