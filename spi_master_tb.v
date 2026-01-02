`timescale 1ns/1ps

module spi_master_tb;

    parameter CLK_PERIOD = 10;
    parameter DATA_WIDTH = 8;
    
    reg                    clk;
    reg                    rst_n;
    reg  [7:0]             clk_div;
    reg                    cpol;
    reg                    cpha;
    reg  [DATA_WIDTH-1:0]  tx_data;
    wire [DATA_WIDTH-1:0]  rx_data;
    reg                    tx_valid;
    wire                   tx_ready;
    wire                   spi_mosi;
    reg                    spi_miso;
    wire                   spi_sclk;
    wire                   spi_ss_n;
    
    spi_master #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clk_div(clk_div),
        .cpol(cpol),
        .cpha(cpha),
        .tx_data(tx_data),
        .rx_data(rx_data),
        .tx_valid(tx_valid),
        .tx_ready(tx_ready),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .spi_sclk(spi_sclk),
        .spi_ss_n(spi_ss_n)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        rst_n = 0;
        clk_div = 8'd4;
        cpol = 0;
        cpha = 0;
        tx_data = 8'd0;
        tx_valid = 0;
        spi_miso = 0;
        
        $dumpfile("spi_master_tb.vcd");
        $dumpvars(0, spi_master_tb);
        
        #100;
        rst_n = 1;
        #100;
        
        $display("========================================");
        $display("Test 1: Sending 0xA5");
        $display("========================================");
        @(posedge clk);
        tx_data = 8'hA5;
        tx_valid = 1;
        @(posedge clk);
        tx_valid = 0;
        
        wait(tx_ready == 1);
        #1000;
        
        $display("========================================");
        $display("Test 2: Sending 0x5A");
        $display("========================================");
        @(posedge clk);
        tx_data = 8'h5A;
        tx_valid = 1;
        @(posedge clk);
        tx_valid = 0;
        
        wait(tx_ready == 1);
        #1000;
        
        $display("========================================");
        $display("Simulation Complete!");
        $display("========================================");
        $finish;
    end
    
    integer bit_cnt = 0;
    reg [7:0] slave_rx_data;
    always @(posedge spi_sclk or posedge spi_ss_n) begin
        if (spi_ss_n) begin
            bit_cnt = 0;
            slave_rx_data = 8'd0;
        end else begin
            if (bit_cnt < 8) begin
                slave_rx_data = {slave_rx_data[6:0], spi_mosi};
                spi_miso = ~spi_mosi;
                bit_cnt = bit_cnt + 1;
            end
        end
    end

endmodule