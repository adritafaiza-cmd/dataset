`timescale 1ns/1ps

module data_sync_tb;
    parameter STAGES = 2;
    parameter DWIDTH = 8;
    integer errors, i, wait_cycles;
    reg clk, rstn, dready_i;
    reg [DWIDTH-1:0] din;
    reg [STAGES-1:0] model_pipe;
    reg [DWIDTH-1:0] model_dout;
    reg model_ready, reset_sampled;
    wire [DWIDTH-1:0] dout;
    wire dready_o;

    data_sync #(.STAGES(STAGES), .DWIDTH(DWIDTH)) dut (
        .clk(clk), .rstn(rstn), .din(din), .dready_i(dready_i),
        .dout(dout), .dready_o(dready_o)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!rstn) begin
            model_pipe <= {STAGES{1'b0}};
            model_dout <= {DWIDTH{1'b0}};
            model_ready <= 1'b0;
            reset_sampled <= 1'b1;
        end else begin
            model_pipe <= {model_pipe[STAGES-2:0], dready_i};
            if (model_pipe[STAGES-1])
                model_dout <= din;
            model_ready <= model_pipe[STAGES-1];
            reset_sampled <= 1'b0;
        end
    end

    always @(negedge clk) begin
        if (dready_o !== model_ready || dout !== model_dout) begin
            $display("CDC VIOLATION [CDC_DATA_STAGE_BEHAVIOR]: dready_o=%b expected_ready=%b dout=%h expected_dout=%h",
                     dready_o, model_ready, dout, model_dout);
            errors = errors + 1;
        end
        if ((^dout) === 1'bx || (dready_o !== 1'b0 && dready_o !== 1'b1)) begin
            $display("CDC VIOLATION [CDC_DATA_X_PROPAGATION]: dready_o=%b dout=%h expected_all_known=1", dready_o, dout);
            errors = errors + 1;
        end
        if (reset_sampled && (dready_o !== 0 || dout !== 0)) begin
            $display("RESET VIOLATION [RESET_SYNC_CLEAR]: reset_sampled=%b dready_o=%b dout=%h expected_ready=0 expected_dout=0", reset_sampled, dready_o, dout);
            errors = errors + 1;
        end
    end

    task send_data;
        input [DWIDTH-1:0] value;
        begin
            @(negedge clk);
            din = value;
            dready_i = 1;
            wait_cycles = 0;
            while ((dready_o !== 1'b1) && (wait_cycles < STAGES + 3)) begin
                @(negedge clk);
                wait_cycles = wait_cycles + 1;
            end
            if (dready_o !== 1'b1 || dout !== value) begin
                $display("CDC VIOLATION [CDC_DATA_CAPTURE_LATENCY]: expected_value=%h dout=%h dready_o=%b observed_cycles=%0d limit=%0d",
                         value, dout, dready_o, wait_cycles, STAGES + 3);
                errors = errors + 1;
            end
            repeat (1 + ($random & 2)) @(negedge clk);
            dready_i = 0;
            wait_cycles = 0;
            while ((dready_o !== 1'b0) && (wait_cycles < STAGES + 3)) begin
                @(negedge clk);
                wait_cycles = wait_cycles + 1;
            end
            if (dready_o !== 1'b0) begin
                $display("CDC VIOLATION [CDC_DATA_READY_RECOVERY]: dready_o=%b observed_cycles=%0d limit=%0d expected=0", dready_o, wait_cycles, STAGES + 3);
                errors = errors + 1;
            end
        end
    endtask

    task reset_phase;
        begin
            #(1 + ($random & 7));
            rstn = 0;
            dready_i = 0;
            repeat (2) @(posedge clk);
            @(negedge clk);
            rstn = 1;
        end
    endtask

    initial begin
        errors = 0;
        rstn = 0; dready_i = 0; din = 0;
        model_pipe = 0; model_dout = 0; model_ready = 0; reset_sampled = 0;
        repeat (3) @(posedge clk);
        @(negedge clk); rstn = 1;

        for (i = 0; i < 24; i = i + 1) begin
            send_data($random);
            if ((i == 7) || (i == 16))
                reset_phase;
        end

        if (errors == 0) $display("DATA SYNC: ALL TESTS PASSED");
        else $display("DATA SYNC: TESTS FAILED (%0d)", errors);
        $finish;
    end

    initial begin
        #50000;
        $display("DATA SYNC: TIMEOUT");
        $finish;
    end
endmodule
