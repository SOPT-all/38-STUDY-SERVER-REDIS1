package com.gyuill.redispractice;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableJpaAuditing
@SpringBootApplication
public class SpringbootRedisPracticeApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringbootRedisPracticeApplication.class, args);
    }
}
