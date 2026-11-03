
package com.umc.movie;

import com.fasterxml.jackson.databind.*;
import com.umc.movie.dto.SignupRequest;
import com.umc.movie.entity.Member;
import com.umc.movie.repository.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.web.servlet.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.stream.Stream;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class Week06ApiTest {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired PasswordEncoder passwords;
    @MockitoSpyBean MemberRepository members;
    @MockitoSpyBean RatingRepository ratings;
    static final String PASSWORD = "Study123!";

    @BeforeEach void cleanTestDatabase() {
        // test profile의 H2에서만 실행합니다. 기존 MySQL 데이터에는 접근하지 않습니다.
        ratings.deleteAll(); members.deleteAll();
    }
    /**
     * MockMvc로 요청을 보내 기대한 HTTP 상태를 확인합니다.
     *
     * @param method POST, PATCH, DELETE 또는 GET
     * @param path 요청 경로
     * @param body null이면 본문 없음, 문자열이면 원시 JSON, 그 외에는 JSON으로 직렬화할 값
     * @param status 기대하는 HTTP 상태 코드
     * @return 응답 JSON과 본문 부재를 추가 검사할 요청 결과
     * @throws Exception 요청 실행 또는 JSON 직렬화가 실패한 경우
     */
    MvcResult send(String method, String path, Object body, int status) throws Exception {
        var request = switch(method) {
            case "POST" -> post(path); case "PATCH" -> patch(path);
            case "DELETE" -> delete(path); default -> get(path);
        };
        if (body != null) request.contentType(MediaType.APPLICATION_JSON)
            .content(body instanceof String text ? text : json.writeValueAsString(body));
        return mvc.perform(request).andExpect(status().is(status)).andReturn();
    }
    Map<String,Object> signupBody(String email, String nickname) {
        return Map.of("email",email,"nickname",nickname,"password",PASSWORD);
    }
    long signup(String email, String nickname) throws Exception {
        return tree(send("POST","/members",signupBody(email,nickname),201)).at("/result/memberId").asLong();
    }
    JsonNode tree(MvcResult response) throws Exception {
        return json.readTree(response.getResponse().getContentAsString(java.nio.charset.StandardCharsets.UTF_8));
    }
    void code(MvcResult response, String expected) throws Exception {
        JsonNode data=tree(response);
        assertFalse(data.get("isSuccess").asBoolean());
        assertEquals(expected,data.get("code").asText());
        assertTrue(data.get("result").isNull());
        assertEquals(Set.of("isSuccess","code","message","result"),
            json.convertValue(data,Map.class).keySet());
        assertFalse(response.getResponse().getContentAsString().contains(PASSWORD));
    }
    void evidence(String name,MvcResult response) throws Exception {
        Path directory=Path.of("build","verification");Files.createDirectories(directory);
        Files.writeString(directory.resolve(name+".json"),json.writerWithDefaultPrettyPrinter().writeValueAsString(tree(response)));
    }
    @Test void signupHashesPasswordAndNeverReturnsIt() throws Exception {
        MvcResult response=send("POST","/members",signupBody("test@example.com","제임스"),201);
        JsonNode body=tree(response);
        assertTrue(body.get("isSuccess").asBoolean());assertEquals("COMMON201",body.get("code").asText());
        assertFalse(body.get("result").has("password"));
        Member saved=members.findByEmail("test@example.com").orElseThrow();
        assertEquals(60,saved.getPassword().length());assertNotEquals(PASSWORD,saved.getPassword());
        assertTrue(passwords.matches(PASSWORD,saved.getPassword()));
        evidence("signup-201",response);
    }
    static Stream<SignupRequest> invalidSignup() {
        return Stream.of(
            new SignupRequest("bad","제임스",PASSWORD),new SignupRequest("","제임스",PASSWORD),
            new SignupRequest(null,"제임스",PASSWORD),new SignupRequest("a@b.com","김",PASSWORD),
            new SignupRequest("a@b.com","가".repeat(13),PASSWORD),new SignupRequest("a@b.com","   ",PASSWORD),
            new SignupRequest("a@b.com","제임스","short"),new SignupRequest("a@b.com","제임스","study123!"),
            new SignupRequest("a@b.com","제임스","STUDY123!"),new SignupRequest("a@b.com","제임스","Studyabc!"),
            new SignupRequest("a@b.com","제임스","Study1234"),new SignupRequest("a@b.com","제임스","Study 123!"),
            new SignupRequest("a@b.com","제임스","Aa1!"+"가".repeat(30)),new SignupRequest("a@b.com","제임스",null));
    }
    @ParameterizedTest @MethodSource("invalidSignup")
    void validatesSignupBeforeSaving(SignupRequest input) throws Exception {
        var response=send("POST","/members",input,400);code(response,"COMMON400");
        assertEquals(0,members.count());evidence("validation-400",response);
    }
    @Test void emailAndNicknameHaveDifferentConflictCodes() throws Exception {
        signup("first@example.com","제임스");
        code(send("POST","/members",signupBody("first@example.com","홀란드"),409),"MEMBER4091");
        code(send("POST","/members",signupBody("second@example.com","제임스"),409),"MEMBER4092");
        assertEquals(1,members.count());
    }
    @Test void ratingCreateUpdateReadDeleteAndDuplicates() throws Exception {
        long member=signup("owner@example.com","주인회원");
        String path="/members/"+member+"/ratings";
        var created=send("POST",path,Map.of("movieId",550,"score",5,"comment","최고의 영화"),201);
        long id=tree(created).get("result").asLong();evidence("rating-201",created);
        code(send("POST",path,Map.of("movieId",550,"score",4),409),"RATING4091");
        send("PATCH",path+"/"+id,Map.of("score",3,"comment","수정한 후기"),200);
        JsonNode list=tree(send("GET",path,null,200));assertEquals(1,list.size());
        assertEquals(3,list.get(0).get("score").asInt());assertEquals("수정한 후기",list.get(0).get("comment").asText());
        long other=signup("other@example.com","다른회원");
        String otherPath="/members/"+other+"/ratings";
        long otherRating=tree(send("POST",otherPath,Map.of("movieId",551,"score",2,"comment","다른 후기"),201)).get("result").asLong();
        JsonNode ownerList=tree(send("GET",path,null,200));
        assertEquals(1,ownerList.size());assertEquals(id,ownerList.get(0).get("ratingId").asLong());
        assertEquals("수정한 후기",ownerList.get(0).get("comment").asText());
        JsonNode otherList=tree(send("GET",otherPath,null,200));
        assertEquals(1,otherList.size());assertEquals(otherRating,otherList.get(0).get("ratingId").asLong());
        assertEquals(2,otherList.get(0).get("score").asInt());assertEquals("다른 후기",otherList.get(0).get("comment").asText());
        var deleted=send("DELETE",path+"/"+id,null,204);
        assertEquals("",deleted.getResponse().getContentAsString());
        assertTrue(tree(send("GET",path,null,200)).isEmpty());
        assertEquals(otherRating,tree(send("GET",otherPath,null,200)).get(0).get("ratingId").asLong());
        code(send("DELETE",path+"/"+id,null,404),"RATING4041");
    }
    @Test void anotherMemberCannotModifyOrDeleteAndMissingRatingIs404() throws Exception {
        long owner=signup("owner@example.com","주인회원");long other=signup("other@example.com","다른회원");
        long id=tree(send("POST","/members/"+owner+"/ratings",Map.of("movieId",550,"score",4),201)).get("result").asLong();
        var forbidden=send("PATCH","/members/"+other+"/ratings/"+id,Map.of("score",1),403);
        code(forbidden,"RATING4031");evidence("ownership-403",forbidden);
        code(send("DELETE","/members/"+other+"/ratings/"+id,null,403),"RATING4031");
        assertEquals(4,ratings.findById(id).orElseThrow().getScore());
        code(send("PATCH","/members/"+owner+"/ratings/999999",Map.of("score",1),404),"RATING4041");
        code(send("DELETE","/members/"+owner+"/ratings/999999",null,404),"RATING4041");
    }
    static Stream<String> invalidRating() {
        return Stream.of("{}","{\"movieId\":0,\"score\":3}","{\"movieId\":550,\"score\":0}",
            "{\"movieId\":550,\"score\":6}","{\"movieId\":550,\"score\":3.5}",
            "{\"movieId\":1.5,\"score\":3}","{\"movieId\":550,\"score\":\"bad\"}",
            "{\"movieId\":550,\"score\":3,\"comment\":\""+"가".repeat(501)+"\"}");
    }
    @ParameterizedTest @MethodSource("invalidRating")
    void rejectsInvalidScoresAndMalformedJson(String input) throws Exception {
        long member=signup("owner@example.com","주인회원");
        code(send("POST","/members/"+member+"/ratings",input,400),"COMMON400");assertEquals(0,ratings.count());
    }
    @Test void missingMemberAndInvalidIdsHaveConsistentErrors() throws Exception {
        code(send("POST","/members/999999/ratings",Map.of("movieId",550,"score",4),404),"MEMBER4041");
        code(send("GET","/members/-1/ratings",null,400),"COMMON400");
        code(send("GET","/members/not-a-number/ratings",null,400),"COMMON400");
        code(send("POST","/members","{broken",400),"COMMON400");
    }
    @Test void legacyGetEndpointsRemainUnwrapped() throws Exception {
        signup("test@example.com","제임스");
        assertFalse(tree(send("GET","/members/nickname/제임스",null,200)).get("available").asBoolean());
        assertFalse(tree(send("GET","/members/email/test@example.com",null,200)).get("available").asBoolean());
        assertTrue(tree(send("GET","/members/nickname/홀란드",null,200)).get("available").asBoolean());
        assertTrue(tree(send("GET","/members/email/unused@example.com",null,200)).get("available").asBoolean());
    }
    @Test void rawJsonSignupAndChecksNormalizePaddedValues() throws Exception {
        String raw="{\"email\":\"  padded@example.com \",\"nickname\":\" 제임스 \",\"password\":\"Study123!\"}";
        JsonNode result=tree(send("POST","/members",raw,201)).get("result");
        assertEquals("padded@example.com",result.get("email").asText());
        assertEquals("제임스",result.get("nickname").asText());
        Member stored=members.findByEmail("padded@example.com").orElseThrow();
        assertEquals("제임스",stored.getNickname());
        assertFalse(tree(mvc.perform(get("/members/nickname").param("nickname"," 제임스 ")).andExpect(status().isOk()).andReturn()).get("available").asBoolean());
        assertFalse(tree(mvc.perform(get("/members/email").param("email","  padded@example.com ")).andExpect(status().isOk()).andReturn()).get("available").asBoolean());
        code(send("POST","/members",signupBody("padded@example.com","홀란드"),409),"MEMBER4091");
        code(send("POST","/members",signupBody("other@example.com","제임스"),409),"MEMBER4092");
        assertEquals(1,members.count());
    }
    @Test void queryChecksAcceptSlashNicknameAndRequireParameters() throws Exception {
        signup("slash@example.com","제임스/홀란드");
        assertFalse(tree(mvc.perform(get("/members/nickname").param("nickname","제임스/홀란드")).andExpect(status().isOk()).andReturn()).get("available").asBoolean());
        assertTrue(tree(mvc.perform(get("/members/nickname").param("nickname","미사용/닉네임")).andExpect(status().isOk()).andReturn()).get("available").asBoolean());
        assertTrue(tree(mvc.perform(get("/members/email").param("email","unused@example.com")).andExpect(status().isOk()).andReturn()).get("available").asBoolean());
        code(send("GET","/members/nickname",null,400),"COMMON400");
        code(send("GET","/members/email",null,400),"COMMON400");
    }
    @Test void patchPreservesOmittedOrNullCommentAndAllowsExplicitEmptyComment() throws Exception {
        long owner=signup("owner@example.com","주인회원");
        String path="/members/"+owner+"/ratings";
        long id=tree(send("POST",path,Map.of("movieId",550,"score",5,"comment","유지할 후기"),201)).get("result").asLong();
        send("PATCH",path+"/"+id,Map.of("score",3),200);
        JsonNode changed=tree(send("GET",path,null,200)).get(0);
        assertEquals(3,changed.get("score").asInt());assertEquals("유지할 후기",changed.get("comment").asText());
        send("PATCH",path+"/"+id,"{\"score\":4,\"comment\":null}",200);
        assertEquals("유지할 후기",tree(send("GET",path,null,200)).get(0).get("comment").asText());
        send("PATCH",path+"/"+id,Map.of("score",2,"comment",""),200);
        assertEquals("",tree(send("GET",path,null,200)).get(0).get("comment").asText());
    }
    /**
     * 두 가입 요청이 사전 중복 검사를 모두 통과하게 해 실제 H2 UNIQUE 충돌을 재현합니다.
     * 201 한 건, 종류별 409 한 건과 저장 회원 한 건을 확인하고 테스트 스레드를 정리합니다.
     *
     * @param nickname true이면 닉네임 충돌, false이면 이메일 충돌을 재현
     * @throws Exception 동시 요청, 제한 시간 내 barrier 통과 또는 응답 검증이 실패한 경우
     */
    @ParameterizedTest @ValueSource(booleans={false,true})
    void databaseUniqueViolationAfterConcurrentPrechecksIs409(boolean nickname) throws Exception {
        CyclicBarrier barrier=new CyclicBarrier(2);
        if (nickname) doAnswer(call->{barrier.await(10,TimeUnit.SECONDS);return false;}).when(members).existsByNickname("동시닉네임");
        else doAnswer(call->{barrier.await(10,TimeUnit.SECONDS);return false;}).when(members).existsByEmail("race@example.com");
        ExecutorService pool=Executors.newFixedThreadPool(2);
        try {
            List<Callable<MvcResult>> calls=new ArrayList<>();
            for(int i=0;i<2;i++) {
                final int number=i;
                calls.add(()->mvc.perform(post("/members").contentType(MediaType.APPLICATION_JSON).content(json.writeValueAsString(
                    signupBody(nickname?"race"+number+"@example.com":"race@example.com",nickname?"동시닉네임":"동시회원"+number)))).andReturn());
            }
            List<MvcResult> results=new ArrayList<>();for(Future<MvcResult> f:pool.invokeAll(calls)) results.add(f.get(20,TimeUnit.SECONDS));
            assertEquals(List.of(201,409),results.stream().map(r->r.getResponse().getStatus()).sorted().toList());
            var conflict=results.stream().filter(r->r.getResponse().getStatus()==409).findFirst().orElseThrow();
            code(conflict,nickname?"MEMBER4092":"MEMBER4091");assertEquals(1,members.count());
            evidence(nickname?"database-nickname-409":"database-email-409",conflict);
        } finally {pool.shutdownNow();}
    }
    @Test void concurrentRatingCreatesCannotBypassCompositeUnique() throws Exception {
        long member=signup("owner@example.com","주인회원");CyclicBarrier barrier=new CyclicBarrier(2);
        doAnswer(call->{barrier.await(10,TimeUnit.SECONDS);return false;}).when(ratings).existsByMember_MemberIdAndMovieId(member,550L);
        ExecutorService pool=Executors.newFixedThreadPool(2);
        try {
            Callable<MvcResult> request=()->mvc.perform(post("/members/"+member+"/ratings").contentType(MediaType.APPLICATION_JSON)
                .content("{\"movieId\":550,\"score\":5}")).andReturn();
            var a=pool.submit(request);var b=pool.submit(request);var responses=List.of(a.get(20,TimeUnit.SECONDS),b.get(20,TimeUnit.SECONDS));
            assertEquals(List.of(201,409),responses.stream().map(r->r.getResponse().getStatus()).sorted().toList());
            assertEquals(1,ratings.count());
            var conflict=responses.stream().filter(r->r.getResponse().getStatus()==409).findFirst().orElseThrow();
            code(conflict,"RATING4091");evidence("database-rating-409",conflict);
        } finally {pool.shutdownNow();}
    }
}
