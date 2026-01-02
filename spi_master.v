module spi_master #(
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst_n,
    input  wire [7:0]              clk_div,
    input  wire                    cpol,
    input  wire                    cpha,
    input  wire [DATA_WIDTH-1:0]   tx_data,
    output reg  [DATA_WIDTH-1:0]   rx_data,
    input  wire                    tx_valid,
    output reg                     tx_ready,
    output reg                     spi_mosi,
    input  wire                    spi_miso,
    output reg                     spi_sclk,
    output reg                     spi_ss_n
);

    localparam IDLE  = 2'b00;
    localparam SETUP = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam DONE  = 2'b11;
    
    reg [1:0] state, next_state;
    reg [7:0] clk_counter;
    reg [4:0] bit_counter;
    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [DATA_WIDTH-1:0] rx_shift_reg;
    reg sclk_enable;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_counter <= 8'd0;
            spi_sclk <= cpol;
        end else begin
            if (sclk_enable) begin
                if (clk_counter >= clk_div) begin
                    clk_counter <= 8'd0;
                    spi_sclk <= ~spi_sclk;
                end else begin
                    clk_counter <= clk_counter + 1'b1;
                end
            end else begin
                clk_counter <= 8'd0;
                spi_sclk <= cpol;
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (tx_valid)
                    next_state = SETUP;
            end
            SETUP: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_counter >= DATA_WIDTH)
                    next_state = DONE;
            end
            DONE: begin
                next_state = IDLE;
            end
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_ready <= 1'b1;
            spi_ss_n <= 1'b1;
            spi_mosi <= 1'b0;
            bit_counter <= 5'd0;
            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            rx_shift_reg <= {DATA_WIDTH{1'b0}};
            rx_data <= {DATA_WIDTH{1'b0}};
            sclk_enable <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    tx_ready <= 1'b1;
                    spi_ss_n <= 1'b1;
                    bit_counter <= 5'd0;
                    sclk_enable <= 1'b0;
                    if (tx_valid) begin
                        tx_shift_reg <= tx_data;
                        tx_ready <= 1'b0;
                    end
                end
                
                SETUP: begin
                    spi_ss_n <= 1'b0;
                    sclk_enable <= 1'b1;
                end
                
                TRANSFER: begin
                    if (clk_counter == 8'd0) begin
                        if (!cpha && !spi_sclk) begin
                            spi_mosi <= tx_shift_reg[DATA_WIDTH-1];
                            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                        end else if (!cpha && spi_sclk) begin
                            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], spi_miso};
                            bit_counter <= bit_counter + 1'b1;
                        end
                        
                        if (cpha && spi_sclk) begin
                            spi_mosi <= tx_shift_reg[DATA_WIDTH-1];
                            tx_shift_reg <= {tx_shift_reg[DATA_WIDTH-2:0], 1'b0};
                        end else if (cpha && !spi_sclk) begin
                            rx_shift_reg <= {rx_shift_reg[DATA_WIDTH-2:0], spi_miso};
                            bit_counter <= bit_counter + 1'b1;
                        end
                    end
                end
                
                DONE: begin
                    sclk_enable <= 1'b0;
                    spi_ss_n <= 1'b1;
                    rx_data <= rx_shift_reg;
                end
            endcase
        end
    end

endmodule