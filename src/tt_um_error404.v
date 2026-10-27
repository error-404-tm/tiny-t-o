`default_nettype none
module top(
    input  wire CLK100MHZ,
    input  wire [0:0] SW,
    input  wire CPU_RESETN,
    input  wire UART_TXD_IN,
    output wire [15:0] LED,
    output wire UART_RXD_OUT
    
);
    
    reg [15:0]  clocks_per_bit = 16'd868;
    wire        uart_start;
    wire [7:0]  uart_data;
    wire        uart_busy;
    //wire [15:0] sample_data;
    wire [15:0] filtered_data;
    //wire        sample_valid;
    wire        output_valid;
    //wire        busy_enable;
    
    wire [7:0]  rx_byte;
    wire        rx_byte_valid;

    wire [15:0] rx_sample;
    wire        rx_sample_valid;
    
    wire        secure_hold;
    
    assign LED[0] = secure_hold;
    assign LED[1] = uart_busy;
    //assign LED[4:2] = debug_state;
    assign LED[15:5] = 14'b0;
    

uart_rx uart_receiver (
    .clk            (CLK100MHZ),
    
    .rx             (UART_TXD_IN),
    .clocks_per_bit (clocks_per_bit),
    
    .data           (rx_byte),
    .data_valid     (rx_byte_valid)
    ); 
    
sample_rx sample_receiver (
    .clk            (CLK100MHZ),

    .uart_data      (rx_byte),
    .uart_valid     (rx_byte_valid),
    .secure_hold    (secure_hold), 
    .sample_data    (rx_sample),
    .sample_valid   (rx_sample_valid)
); 
   
moving_average filter (
    .clk            (CLK100MHZ),
    
    .reset          (!CPU_RESETN),
    .sample_valid   (rx_sample_valid),
    .sample_in      (rx_sample),
    .secure_hold    (secure_hold), 
    .sample_out     (filtered_data),
    .output_valid   (output_valid)
    );
   
sample_tx sample_transceiver (
    .clk            (CLK100MHZ),
    
    .sample_valid   (output_valid),
    .sample_data    (filtered_data),
    .uart_busy      (uart_busy),
    .uart_start     (uart_start),
    .secure_hold    (secure_hold), 
    .uart_data      (uart_data)
    );

    
uart_tx uart_transceiver (
    .clk            (CLK100MHZ),
    
    .start          (uart_start),
    .data           (uart_data),
    .clocks_per_bit (clocks_per_bit),
    
    .tx             (UART_RXD_OUT),
    .busy           (uart_busy)
    );
    
security_ctrl lid_sensor (
    .clk            (CLK100MHZ),
    .lid_switch     (SW[0]),
    .secure_hold    (secure_hold),  
    .cmd_valid      (rx_byte_valid),
    .cmd_byte       (rx_byte),
    .debug_state    (LED[4:2])
    );

endmodule