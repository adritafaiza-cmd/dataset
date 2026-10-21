module pulse_sync #(
    parameter STAGES = 2
)(
    input  clk_a,
    input  rstn_a,
    input  clk_b,
    input  rstn_b,
    input  pulseA_i,
    output pulseB_o,
    output busy_o
);

    // Internal signals for the FIFO
    reg [STAGES-1:0] full;
    reg [STAGES-1:0] empty;
    reg [STAGES-1:0] data;

    // Write pointer (domain A)
    reg [STAGES-1:0] write_ptr;
    // Read pointer (domain B)
    reg [STAGES-1:0] read_ptr;

    // Write enable: only allow one pulse through
    reg write_en;

    // Generate full and empty flags
    assign full = (write_ptr == read_ptr) && (data[STAGES-1] == 1'b1);
    assign empty = (write_ptr == read_ptr) && (data[STAGES-1] == 1'b0);

    // Write logic in domain A
    always @(posedge clk_a or negedge rstn_a) begin
        if (!rstn_a) begin
            write_ptr <= 0;
            data <= 0;
            write_en <= 0;
        end else begin
            if (pulseA_i && !empty) begin
                write_en <= 1;
                data <= {1'b1, data[STAGES-2:0]};
                write_ptr <= write_ptr + 1;
            end else begin
                write_en <= 0;
                data <= {1'b0, data[STAGES-2:0]};
                write_ptr <= write_ptr;
            end
        end
    end

    // Read logic in domain B
    always @(posedge clk_b or negedge rstn_b) begin
        if (!rstn_b) begin
            read_ptr <= 0;
            data <= 0;
            pulseB_o <= 0;
            busy_o <= 0;
        end else begin
            if (write_en) begin
                pulseB_o <= 1;
                busy_o <= 1;
                data <= {1'b0, data[STAGES-2:0]};
                read_ptr <= read_ptr + 1;
            end else begin
                pulseB_o <= 0;
                busy_o <= 0;
                data <= {1'b0, data[STAGES-2:0]};
                read_ptr <= read_ptr;
            end
        end
    end

    // Output busy_o is high when there is data in the FIFO
    assign busy_o = (write_ptr != read_ptr) || (data[STAGES-1] == 1'b1);

endmodule<|im_end|>
