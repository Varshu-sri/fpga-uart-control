module uart_tx_rx_v5 (
    input wire clk,                // 50 MHz
    input wire [3:0] sw,
    input wire uart_rx,            
    output reg uart_tx,
    output reg uart_rts,           
    output reg freq_out
);

parameter CLK_FREQ = 50000000;
parameter BAUD_RATE = 115200;
parameter CLKS_PER_BIT = 434;

reg [31:0] divider;
reg [31:0] counter = 0;
reg [15:0] freq_value;
reg [15:0] last_freq = 16'hFFFF;

// PWM Pulse Width Signals
reg [31:0] pulse_width_limit = 50000; 
reg [31:0] temp_val = 0;             

// UART RX Signals (with Double Synchronization)
reg rx_sync_0, rx_sync_1;
always @(posedge clk) begin
    rx_sync_0 <= uart_rx;
    rx_sync_1 <= rx_sync_0; // Use rx_sync_1 for logic
end

reg [7:0]  rx_byte;
reg [3:0]  rx_bit_index = 0;
reg [15:0] rx_baud_cnt = 0;
reg        rx_busy = 0;

// ==========================================================
// ROBUST UART RECEIVE LOGIC
// ==========================================================
always @(posedge clk) begin
    if (!rx_busy && !rx_sync_1) begin 
        rx_busy <= 1;
        rx_baud_cnt <= 0;
        rx_bit_index <= 0;
    end else if (rx_busy) begin
        if (rx_baud_cnt < CLKS_PER_BIT - 1) begin
            rx_baud_cnt <= rx_baud_cnt + 1;
        end else begin
            rx_baud_cnt <= 0;
            if (rx_bit_index < 8) begin
                rx_byte[rx_bit_index] <= rx_sync_1;
                rx_bit_index <= rx_bit_index + 1;
            end else begin
                rx_busy <= 0; // Stop bit reached
                if (rx_byte >= 8'h30 && rx_byte <= 8'h39) begin
                    temp_val <= (temp_val * 10) + (rx_byte - 8'h30);
                end else if (rx_byte == 8'h0A || rx_byte == 8'h0D) begin
                    if (temp_val > 0) pulse_width_limit <= temp_val * 50000;
                    temp_val <= 0; 
                end
            end
        end
    end
end

// ==========================================================
// PWM LOGIC WITH SAFETY CLAMP
// ==========================================================


always @(posedge clk) begin
    if (sw[0])      begin divider <= 500000; freq_value <= 100; end 
    else if (sw[1]) begin divider <= 250000; freq_value <= 200; end 
    else if (sw[2]) begin divider <= 125000; freq_value <= 400; end 
    else            begin divider <= 0;      freq_value <= 0;   end

    if (divider == 0) begin
        freq_out <= 0;
        counter  <= 0;
    end else begin
        if (counter >= divider - 1) counter <= 0;
        else counter <= counter + 1;

        // CLAMP: Pulse cannot be longer than Period minus a small buffer
        // This prevents the "PWM stays high" error when changing switches
        if (counter < pulse_width_limit && counter < (divider - 100))
            freq_out <= 1'b1;
        else
            freq_out <= 1'b0;
    end
end


// ==========================================================
// UART TRANSMISSION STATE MACHINE (Frequency to GUI)
// ==========================================================

reg [7:0]  message [0:3];
reg [1:0]  msg_index = 0;
reg [3:0]  bit_index = 0;
reg [15:0] baud_counter = 0;
reg [9:0]  tx_shift = 10'b1111111111;
localparam IDLE=2'b00, LOAD_BYTE=2'b01, TRANSMIT=2'b10;
reg [1:0] state = IDLE;

always @(posedge clk) begin
    case (state)
        IDLE: begin
            uart_tx  <= 1'b1;
            uart_rts <= 1'b0;
            if (freq_value != last_freq) begin
                last_freq <= freq_value;
                msg_index <= 0;
                state <= LOAD_BYTE;
                case (freq_value)
                    100: begin message[0]<="1"; message[1]<="0"; message[2]<="0"; message[3]<="\n"; end
                    200: begin message[0]<="2"; message[1]<="0"; message[2]<="0"; message[3]<="\n"; end
                    400: begin message[0]<="4"; message[1]<="0"; message[2]<="0"; message[3]<="\n"; end
                    default: begin message[0]<="0"; message[1]<="\n"; message[2]<=8'h00; message[3]<=8'h00; end
                endcase
            end
        end
        LOAD_BYTE: begin
            tx_shift <= {1'b1, message[msg_index], 1'b0};
            bit_index <= 0;
            baud_counter <= 0;
            state <= TRANSMIT;
        end
        TRANSMIT: begin
            if (baud_counter < CLKS_PER_BIT - 1) baud_counter <= baud_counter + 1;
            else begin
                baud_counter <= 0;
                uart_tx <= tx_shift[bit_index];
                if (bit_index == 9) begin
                    if ((freq_value == 0 && msg_index == 0) || msg_index == 3) state <= IDLE;
                    else begin msg_index <= msg_index + 1; state <= LOAD_BYTE; end
                end else bit_index <= bit_index + 1;
            end
        end
    endcase
end

endmodule 