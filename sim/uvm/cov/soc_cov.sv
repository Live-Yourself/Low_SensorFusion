`uvm_analysis_imp_decl(_apb_cov)

class soc_cov extends uvm_component;
	`uvm_component_utils(soc_cov)

	// Aggregator receives APB transactions once and forwards to each peripheral-specific collector.
	uvm_analysis_imp_apb_cov#(apb_seq_item, soc_cov) apb_imp;
	cov_i2c m_cov_i2c;
	cov_udma m_cov_udma;

	function new(string name = "soc_cov", uvm_component parent = null);
		super.new(name, parent);
		apb_imp = new("apb_imp", this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		m_cov_i2c  = cov_i2c::type_id::create("m_cov_i2c", this);
		m_cov_udma = cov_udma::type_id::create("m_cov_udma", this);
	endfunction

	function void write_apb_cov(apb_seq_item tr);
		bit i2c_hit;
		bit udma_hit;

		// Important logic: each sub-collector decides whether this APB transaction is in its ownership window.
		// This keeps address decode and covergroup semantics local to each IP, improving reuse.
		m_cov_i2c.sample_apb(tr, i2c_hit);
		m_cov_udma.sample_apb(tr, udma_hit);
	endfunction

	function void report_phase(uvm_phase phase);
		real cov_total;
		real cov_i2c_ctrl;
		real cov_i2c_cmd;
		real cov_udma_len;
		int unsigned w_i2c;
		int unsigned w_udma;
		int unsigned samples_total;

		super.report_phase(phase);

		cov_i2c_ctrl = m_cov_i2c.get_cov_ctrl();
		cov_i2c_cmd  = m_cov_i2c.get_cov_cmd();
		cov_udma_len = m_cov_udma.get_cov_len();
		w_i2c        = m_cov_i2c.get_cov_weight();
		w_udma       = m_cov_udma.get_cov_weight();
		samples_total = m_cov_i2c.get_samples() + m_cov_udma.get_samples();

		// Important logic: weighted merge by bin count, so high-dimensional groups are not under-represented.
		cov_total = (m_cov_i2c.get_cov_total() * w_i2c + m_cov_udma.get_cov_total() * w_udma) / (w_i2c + w_udma);

		// Standard line required by run_summarize.sh parser.
		`uvm_info("SOC_COV", $sformatf("functional_coverage=%0.2f%% samples=%0d", cov_total, samples_total), UVM_LOW)
		// Detail line for debug and closure review.
		`uvm_info("SOC_COV", $sformatf("cov_i2c_ctrl=%0.2f%% cov_i2c_cmd=%0.2f%% cov_udma_len=%0.2f%%",
			cov_i2c_ctrl, cov_i2c_cmd, cov_udma_len), UVM_LOW)
	endfunction
endclass
