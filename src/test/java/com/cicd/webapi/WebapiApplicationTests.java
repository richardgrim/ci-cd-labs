package com.cicd.webapi;

//import java.beans.Transient;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;


import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
class WebapiApplicationTests {

	@Autowired
	private MockMvc MockMvc;

	@Test
	void contextLoads() {
	}

	@Test
	void checkHealthyResponse() throws Exception {
		MockMvc.perform(get("/health")
				.accept(MediaType.TEXT_PLAIN))
			.andExpect(status().isOk())
			.andExpect(content().string("Server Healthy!"));
	}

	@Test
	void checkDateResponse() throws Exception {
		MockMvc.perform(get("/date")
				.accept(MediaType.TEXT_PLAIN))
			.andExpect(status().isOk())
			.andExpect(content().string("Current Server Date: " + java.time.LocalDate.now()));
			//.andExpect(content().string("Current Server Date Time : " + java.time.LocalDateTime.now()));
	}

}