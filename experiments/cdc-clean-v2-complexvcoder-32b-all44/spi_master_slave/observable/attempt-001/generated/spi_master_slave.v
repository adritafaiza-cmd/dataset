module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // Internal signals
    reg [N-1:0]        wren_sclk;
    reg [N-1:0]        di_sclk;
    reg [N-1:0]        do_sclk;
    reg                spi_clk_div;
    reg [3:0]          bit_cnt;
    reg [N-1:0]        shift_reg;
    reg [1:0]          state, next_state;
    reg                wr_ack_sclk;
    reg                do_valid_sclk;

    // State definitions
    localparam IDLE   = 2'b00;
    localparam LOAD   = 2'b01;
    localparam SHIFT  = 2'b10;
    localparam STORE  = 2'b11;

    // Clock-domain crossing for wren_i to sclk
    crossover #(.N(1)) crossover_wren (
        .sclk(sclk_i),
        .pclk(pclk_i),
        .rst(rst_i),
        .data_in(wren_i),
        .data_out(wren_sclk[0])
    );

    // Clock-domain crossing for di_i to sclk
    crossover #(.N(N)) crossover_di (
        .sclk(sclk_i),
        .pclk(pclk_i),
        .rst(rst_i),
        .data_in(di_i),
        .data_out(di_sclk)
    );

    // Clock-domain crossing for do_o from sclk to pclk
    crossover #(.N(N)) crossover_do (
        .sclk(sclk_i),
        .pclk(pclk_i),
        .rst(rst_i),
        .data_in(do_sclk),
        .data_out(do_o)
    );

    // SPI clock generation
    reg [1:0] clk_div_counter;
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            clk_div_counter <= 2'b00;
            spi_clk_div <= 1'b0;
        end else begin
            if (clk_div_counter == SPI_2X_CLK_DIV - 1) begin
                clk_div_counter <= 2'b00;
                spi_clk_div <= ~spi_clk_div;
            end else begin
                clk_div_counter <= clk_div_counter + 1;
            end
        end
    end

    // SPI clock output
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            spi_sck_o <= 1'b0;
        else
            spi_sck_o <= spi_clk_div;
    end

    // State machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (wren_sclk[0]) begin
                    next_state = LOAD;
                end
            end
            LOAD: begin
                next_state = SHIFT;
            end
            SHIFT: begin
                if (bit_cnt == N - 1) begin
                    next_state = STORE;
                end
            end
            STORE: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // State actions
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b1;
            wr_ack_sclk <= 1'b0;
            do_valid_sclk <= 1'b0;
            bit_cnt <= 4'b0000;
            shift_reg <= {N{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    di_req_o <= 1'b1;
                    wr_ack_sclk <= 1'b0;
                    do_valid_sclk <= 1'b0;
                end
                LOAD: begin
                    spi_ssel_o <= 1'b1;
                    shift_reg <= di_sclk;
                    bit_cnt <= 4'b0000;
                end
                SHIFT: begin
                    if (spi_clk_div) begin
                        spi_mosi_o <= shift_reg[N-1];
                        shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                        bit_cnt <= bit_cnt + 1;
                    end
                end
                STORE: begin
                    spi_ssel_o <= 1'b0;
                    do_sclk <= shift_reg;
                    do_valid_sclk <= 1'b1;
                    wr_ack_sclk <= 1'b1;
                    di_req_o <= 1'b0;
                end
                default: begin
                    spi_ssel_o <= 1'b0;
                    spi_mosi_o <= 1'b0;
                    di_req_o <= 1'b1;
                    wr_ack_sclk <= 1'b0;
                    do_valid_sclk <= 1'b0;
                end
            endcase
        end
    end

    // Handshake signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
        end else begin
            wr_ack_o <= wr_ack_sclk;
            do_valid_o <= do_valid_sclk;
        end
    end

endmodule

module crossover #(
    parameter N = 8
)(
    input              sclk,
    input              pclk,
    input              rst,
    input  [N-1:0]     data_in,
    output reg [N-1:0] data_out
);

    reg [N-1:0] reg1;
    reg [N-1:0] reg2;

    always @(posedge pclk or posedge rst) begin
        if (rst) begin
            reg1 <= {N{1'b0}};
        end else begin
            reg1 <= data_in;
        end
    end

    always @(posedge sclk or posedge rst) begin
        if (rst) begin
            reg2 <= {N{1'b0}};
        end else begin
            reg2 <= reg1;
        end
    end

    assign data_out = reg2;

endmodule
