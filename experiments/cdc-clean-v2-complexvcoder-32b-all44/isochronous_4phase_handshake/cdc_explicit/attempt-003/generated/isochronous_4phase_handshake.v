module isochronous_4phase_handshake (
    input  src_clk_i,
    input  src_rst_ni,
    input  src_valid_i,
    output src_ready_o,
    input  dst_clk_i,
    input  dst_rst_ni,
    output dst_valid_o,
    input  dst_ready_i
);

    wire [1:0] src_phase_o;
    wire [1:0] dst_phase_o;
    wire [1:0] synced_src_phase;
    wire [1:0] synced_dst_phase;

    phase_detector phase_detector_src (
        .clk      (src_clk_i),
        .rst_n    (src_rst_ni),
        .valid_i  (src_valid_i),
        .ready_o  (src_ready_o),
        .phase_o  (src_phase_o)
    );

    phase_detector phase_detector_dst (
        .clk      (dst_clk_i),
        .rst_n    (dst_rst_ni),
        .valid_i  (dst_ready_i),
        .ready_o  (/* Not used */),
        .phase_o  (dst_phase_o)
    );

    synchronizer sync_src_to_dst (
        .clk_src  (src_clk_i),
        .rst_src_n(src_rst_ni),
        .data_i   (src_phase_o),
        .clk_dst  (dst_clk_i),
        .rst_dst_n(dst_rst_ni),
        .data_o   (synced_src_phase)
    );

    synchronizer sync_dst_to_src (
        .clk_src  (dst_clk_i),
        .rst_src_n(dst_rst_ni),
        .data_i   (dst_phase_o),
        .clk_dst  (src_clk_i),
        .rst_dst_n(src_rst_ni),
        .data_o   (synced_dst_phase)
    );

    handshake_controller handshake_ctrl (
        .clk_src  (src_clk_i),
        .rst_src_n(src_rst_ni),
        .clk_dst  (dst_clk_i),
        .rst_dst_n(dst_rst_ni),
        .src_phase_i(synced_src_phase),
        .dst_phase_i(synced_dst_phase),
        .src_ready_o(src_ready_o),
        .dst_valid_o(dst_valid_o)
    );

endmodule

module phase_detector (
    input  clk,
    input  rst_n,
    input  valid_i,
    output ready_o,
    output [1:0] phase_o
);

    reg [1:0] phase_reg;
    wire [1:0] next_phase;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_reg <= 2'b00;
        end else begin
            phase_reg <= next_phase;
        end
    end

    always @(*) begin
        case (phase_reg)
            2'b00: next_phase = valid_i ? 2'b01 : 2'b00;
            2'b01: next_phase = valid_i ? 2'b10 : 2'b00;
            2'b10: next_phase = valid_i ? 2'b11 : 2'b00;
            2'b11: next_phase = valid_i ? 2'b00 : 2'b11;
            default: next_phase = 2'b00;
        endcase
    end

    assign ready_o = (phase_reg == 2'b00) ? 1'b1 : 1'b0;
    assign phase_o = phase_reg;

endmodule

module synchronizer (
    input  clk_src,
    input  rst_src_n,
    input  [1:0] data_i,
    input  clk_dst,
    input  rst_dst_n,
    output [1:0] data_o
);

    reg [1:0] sync_reg1;
    reg [1:0] sync_reg2;

    always @(posedge clk_src or negedge rst_src_n) begin
        if (!rst_src_n) begin
            sync_reg1 <= 2'b00;
        end else begin
            sync_reg1 <= data_i;
        end
    end

    always @(posedge clk_dst or negedge rst_dst_n) begin
        if (!rst_dst_n) begin
            sync_reg2 <= 2'b00;
        end else begin
            sync_reg2 <= sync_reg1;
        end
    end

    assign data_o = sync_reg2;

endmodule

module handshake_controller (
    input  clk_src,
    input  rst_src_n,
    input  clk_dst,
    input  rst_dst_n,
    input  [1:0] src_phase_i,
    input  [1:0] dst_phase_i,
    output src_ready_o,
    output dst_valid_o
);

    reg src_ready_reg;
    reg dst_valid_reg;

    always @(posedge clk_src or negedge rst_src_n) begin
        if (!rst_src_n) begin
            src_ready_reg <= 1'b0;
        end else begin
            case (src_phase_i)
                2'b00: src_ready_reg <= (dst_phase_i == 2'b00);
                2'b01: src_ready_reg <= (dst_phase_i == 2'b11);
                2'b10: src_ready_reg <= (dst_phase_i == 2'b00);
                2'b11: src_ready_reg <= (dst_phase_i == 2'b01);
                default: src_ready_reg <= 1'b0;
            endcase
        end
    end

    always @(posedge clk_dst or negedge rst_dst_n) begin
        if (!rst_dst_n) begin
            dst_valid_reg <= 1'b0;
        end else begin
            case (dst_phase_i)
                2'b00: dst_valid_reg <= (src_phase_i == 2'b01);
                2'b01: dst_valid_reg <= (src_phase_i == 2'b10);
                2'b10: dst_valid_reg <= (src_phase_i == 2'b11);
                2'b11: dst_valid_reg <= (src_phase_i == 2'b00);
                default: dst_valid_reg <= 1'b0;
            endcase
        end
    end

    assign src_ready_o = src_ready_reg;
    assign dst_valid_o = dst_valid_reg;

endmodule
