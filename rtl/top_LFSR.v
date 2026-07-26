module top_LSFR
    #(
        parameter SEED       = 16'hFFFF,
        parameter CYCLES     = 5,
        parameter LOCK_THR   = 2,
        parameter UNLOCK_THR = 5
    )
    (
        // ==========================================
        // 1. COMUNES
        // ==========================================
        input  wire        clock,
        input  wire        i_rst,             // Reset general asíncrono
        
        // ==========================================
        // 2. GENERADOR
        // ==========================================
        // ----> Inputs 
        input  wire        i_gen_enable,          
        input  wire        i_soft_reset,      // Reset síncrono
        input  wire [15:0] i_seed,            // Seed dinámica para reset síncrono
        input  wire        i_gen_valid,           
        
        // ----> Outputs 
        output wire [15:0] o_lfsr,            // Salida de datos del generador LFSR
        output wire        o_gen_valid,          

        // ==========================================
        // 3. CHECKER
        // ==========================================
        // ----> Inputs
        input  wire        i_checker_enable,  
        
        // ----> Outputs 
        output wire [15:0] o_checker,         // Salida de datos del checker
        output wire        o_locked           // Estado de sincronía (lock) del checker
    );

    // =========================================================================
    // INSTANCIA DEL GENERADOR LFSR
    // =========================================================================
    lfsr #(
        .SEED(SEED)
    ) u_generator (
        // Inputs
        .clock        (clock),
        .i_rst        (i_rst),
        .i_soft_reset (i_soft_reset),
        .i_enable     (i_gen_enable),
        .i_valid      (i_gen_valid),
        .i_seed       (i_seed),
        
        // Outputs (Se conectan directamente a las salidas del top)
        .lfsr         (o_lfsr),
        .o_valid      (o_gen_valid)
    );


    // =========================================================================
    // INSTANCIA DEL CHECKER
    // =========================================================================

    lfsr_checker #(
        .LOCK_THR   (LOCK_THR),
        .UNLOCK_THR (UNLOCK_THR)
    ) u_checker (
        // Inputs
        .clock        (clock),
        .i_rst        (i_rst),
        .i_enable     (i_checker_enable),
        
        // Entradas de datos provenientes del generador
        .i_valid      (o_gen_valid), // Conectado a la salida valid del generador
        .i_lfsr       (o_lfsr),  // Conectado a la salida de datos del generador
        
        // Outputs
        .o_checker     (o_checker), // Salida de datos del checker hacia el exterior
        .o_lock       (o_locked) // Salida de lock hacia el exterior
    );
endmodule
