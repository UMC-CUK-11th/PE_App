package com.umc.movie;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.Level;
import ch.qos.logback.core.read.ListAppender;
import ch.qos.logback.classic.spi.ILoggingEvent;
import com.umc.movie.exception.GlobalExceptionHandler;
import com.umc.movie.repository.MemberRepository;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.mock;

class GlobalExceptionHandlerTest {
    @Test void unexpectedErrorIsLoggedButNotExposedToClient() {
        Logger logger=(Logger)LoggerFactory.getLogger(GlobalExceptionHandler.class);
        ListAppender<ILoggingEvent> events=new ListAppender<>();
        events.start();logger.addAppender(events);
        try {
            var handler=new GlobalExceptionHandler(mock(MemberRepository.class));
            var response=handler.unexpected(new IllegalStateException("test-internal-detail"));
            assertEquals(500,response.getStatusCode().value());
            assertEquals("COMMON500",response.getBody().code());
            assertFalse(response.getBody().message().contains("test-internal-detail"));
            assertNull(response.getBody().result());
            assertEquals(1,events.list.size());
            assertEquals(Level.ERROR,events.list.get(0).getLevel());
            assertNotNull(events.list.get(0).getThrowableProxy());
            assertEquals("java.lang.IllegalStateException",events.list.get(0).getThrowableProxy().getClassName());
        } finally {
            logger.detachAppender(events);events.stop();
        }
    }
}
