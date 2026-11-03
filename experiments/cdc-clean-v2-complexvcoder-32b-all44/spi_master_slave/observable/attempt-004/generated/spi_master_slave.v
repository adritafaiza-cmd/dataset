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
    reg                wren_sync_o;
    reg                rst_sync_o;
    reg                do_valid_o_sclk;
    reg [N-1:0]        do_o_sclk;
    reg [N-1:0]        shift_reg;
    reg [3:0]          bit_cnt;
    reg [2:0]          state, next_state;
    reg [3:0]          sclk_div;
    reg                sclk_edge, sclk_edge_d;

    // State definitions
    localparam IDLE     = 3'b000;
    localparam START    = 3'b001;
    localparam TRANSFER = 3'b010;
    localparam STOP     = 3'b011;

    // CDC synchronization for wren_i
    cdc_sync wren_sync (
        .clk_i  (pclk_i),
        .clk_o  (sclk_i),
        .rst_i  (rst_i),
        .data_i (wren_i),
        .data_o (wren_sync_o)
    );

    // CDC synchronization for rst_i
    cdc_sync rst_sync (
        .clk_i  (pclk_i),
        .clk_o  (sclk_i),
        .rst_i  (rst_i),
        .data_i (rst_i),
        .data_o (rst_sync_o)
    );

    // CDC synchronization for do_valid_o_sclk
    cdc_sync do_valid_sync (
        .clk_i  (sclk_i),
        .clk_o  (pclk_i),
        .rst_i  (rst_i),
        .data_i (do_valid_o_sclk),
        .data_o (do_valid_o)
    );

    // Generate sclk_edge signal on rising edge of sclk_i
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_edge_d <= 1'b0;
            sclk_edge   <= 1'b0;
        end else begin
            sclk_edge_d <= sclk_i;
            sclk_edge   <= sclk_i & ~sclk_edge_d;
        end
    end

    // Divide sclk_i by SPI_2X_CLK_DIV to create sclk_edge signal
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div <= 4'b0;
        end else if (sclk_edge) begin
            sclk_div <= sclk_div + 1;
        end
    end

    // State machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (wren_sync_o) begin
                    next_state = START;
                end
            end
            START: begin
                next_state = TRANSFER;
            end
            TRANSFER: begin
                if (bit_cnt == N-1) begin
                    next_state = STOP;
                end
            end
            STOP: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // State machine actions
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o   <= 1'b0;
            spi_sck_o    <= 1'b0;
            spi_mosi_o   <= 1'b0;
            di_req_o     <= 1'b1;
            wr_ack_o     <= 1'b0;
            do_valid_o_sclk <= 1'b0;
            do_o_sclk    <= {N{1'b0}};
            shift_reg    <= {N{1'b0}};
            bit_cnt      <= 4'b0;
        end else begin
            case (state)
                IDLE: begin
                    di_req_o <= 1'b1;
                    wr_ack_o <= 1'b0;
                    do_valid_o_sclk <= 1'b0;
                    if (wren_sync_o) begin
                        wr_ack_o <= 1'b1;
                        shift_reg <= di_i;
                        bit_cnt <= 4'b0;
                        di_req_o <= 1'b0;
                    end
                end
                START: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o  <= 1'b0;
                    spi_mosi_o <= shift_reg[N-1];
                end
                TRANSFER: begin
                    if (sclk_edge && sclk_div == SPI_2X_CLK_DIV-1) begin
                        spi_sck_o  <= ~spi_sck_o;
                        if (spi_sck_o) begin
                            shift_reg <= {shift_reg[N-2:0], spi_miso_i};
                            bit_cnt   <= bit_cnt + 1;
                        end
                    end
                end
                STOP: begin
                    spi_ssel_o <= 1'b0;
                    do_o_sclk  <= shift_reg;
                    do_valid_o_sclk <= 1'b1;
                end
                default: begin
                    spi_ssel_o   <= 1'b0;
                    spi_sck_o    <= 1'b0;
                    spi_mosi_o   <= 1'b0;
                    di_req_o     <= 1'b1;
                    wr_ack_o     <= 1'b0;
                    do_valid_o_sclk <= 1'b0;
                    do_o_sclk    <= {N{1'b0}};
                    shift_reg    <= {N{1'b0}};
                    bit_cnt      <= 4'b0;
                end
            endcase
        end
    end

    // Output assignment
    assign do_o = do_o_sclk;

endmodule

module cdc_sync (
    input  clk_i,
    input  clk_o,
    input  rst_i,
    input  data_i,
    output reg data_o
);

    reg data_sync1, data_sync2;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            data_sync1 <= 1'b0;
        end else begin
            data_sync1 <= data_i;
        end
    end

    always @(posedge clk_o or posedge rst_i) begin
        if (rst_i) begin
            data_sync2 <= 1'b0;
            data_o     <= 1'b0;
        end else begin
            data_sync2 <= data_sync1;
            data_o     <= data_sync2;
        end
    end

endmodule
