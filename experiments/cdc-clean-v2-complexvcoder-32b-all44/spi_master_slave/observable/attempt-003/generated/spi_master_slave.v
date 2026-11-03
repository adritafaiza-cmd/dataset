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
    reg                wren_synced;
    reg                miso_synced;
    reg [N-1:0]        shift_reg;
    reg [3:0]          bit_count;
    reg [2:0]          state;
    reg [2:0]          next_state;
    reg [N-1:0]        do_reg;

    // States
    localparam IDLE         = 3'b000;
    localparam TRANSMITTING = 3'b001;
    localparam RECEIVING    = 3'b010;
    localparam TURNAROUND   = 3'b011;

    // SPI clock divider
    reg [1:0] sclk_div_cnt;
    reg       sclk;

    // SPI clock generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            sclk_div_cnt <= 2'b00;
            sclk         <= 1'b0;
        end else begin
            if (sclk_div_cnt == SPI_2X_CLK_DIV - 1) begin
                sclk_div_cnt <= 2'b00;
                sclk         <= ~sclk;
            end else begin
                sclk_div_cnt <= sclk_div_cnt + 1;
            end
        end
    end

    // State machine
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (wren_synced) begin
                    next_state = TRANSMITTING;
                end
            end
            TRANSMITTING: begin
                if (bit_count == N - 1)
                    next_state = RECEIVING;
            end
            RECEIVING: begin
                if (bit_count == N - 1)
                    next_state = TURNAROUND;
            end
            TURNAROUND: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Shift register and bit count
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            bit_count <= 4'b0000;
            shift_reg <= {N{1'b0}};
        end else begin
            case (state)
                TRANSMITTING: begin
                    if (sclk) begin
                        bit_count <= bit_count + 1;
                        shift_reg <= {shift_reg[N-2:0], 1'b0};
                    end
                end
                RECEIVING: begin
                    if (sclk) begin
                        bit_count <= bit_count + 1;
                        shift_reg <= {miso_synced, shift_reg[N-1:1]};
                    end
                end
                TURNAROUND: begin
                    bit_count <= 4'b0000;
                end
            endcase
        end
    end

    // SPI signals
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o  <= 1'b0;
            spi_mosi_o <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o  <= 1'b0;
                    spi_mosi_o <= 1'b0;
                end
                TRANSMITTING, RECEIVING: begin
                    spi_ssel_o <= 1'b0;
                    spi_sck_o  <= sclk;
                    if (state == TRANSMITTING)
                        spi_mosi_o <= shift_reg[N-1];
                end
                TURNAROUND: begin
                    spi_ssel_o <= 1'b1;
                    spi_sck_o  <= 1'b0;
                end
            endcase
        end
    end

    // Parallel interface signals
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o   <= 1'b1;
            wr_ack_o   <= 1'b0;
            do_valid_o <= 1'b0;
            do_o       <= {N{1'b0}};
        end else begin
            di_req_o   <= (state == IDLE) ? 1'b1 : 1'b0;
            wr_ack_o   <= (state == TRANSMITTING && bit_count == 0) ? 1'b1 : 1'b0;
            do_valid_o <= (state == TURNAROUND) ? 1'b1 : 1'b0;
            do_o       <= (state == TURNAROUND) ? shift_reg : do_o;
        end
    end

    // Clock domain crossing synchronizers
    cd_sync sync_wren (
        .clk_i  (sclk_i),
        .rst_i  (rst_i),
        .data_i (wren_i),
        .data_o (wren_synced)
    );

    cd_sync sync_miso (
        .clk_i  (pclk_i),
        .rst_i  (rst_i),
        .data_i (spi_miso_i),
        .data_o (miso_synced)
    );

endmodule

module cd_sync (
    input  clk_i,
    input  rst_i,
    input  data_i,
    output reg data_o
);

    reg sync_reg1;
    reg sync_reg2;

    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            sync_reg1 <= 1'b0;
            sync_reg2 <= 1'b0;
        end else begin
            sync_reg1 <= data_i;
            sync_reg2 <= sync_reg1;
        end
    end

    assign data_o = sync_reg2;

endmodule
