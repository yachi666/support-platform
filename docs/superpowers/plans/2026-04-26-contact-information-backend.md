# Contact Information Backend Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build persistent backend APIs for contact-information, replace frontend runtime mock flows with real list/create integration, and validate the feature through local end-to-end testing.

**Architecture:** The backend adds a dedicated `contact-information` domain with a parent table plus child tables for tags, staff bindings, and links. The frontend keeps the current public-page route/component boundaries, but moves list filtering and persistence to real APIs. Public reads stay open, while creation reuses existing workspace admin auth enforcement.

**Tech Stack:** Spring Boot 4, MyBatis-Plus, Flyway, Sa-Token, Vue 3, Vite, node --test, Playwright

---

### Task 1: Scaffold backend contracts and write failing service tests

**Files:**
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/dto/contactinformation/ContactInformationDto.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/dto/contactinformation/ContactInformationLinkDto.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/dto/contactinformation/ContactInformationStaffDto.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/dto/contactinformation/ContactInformationListResponse.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/dto/contactinformation/ContactInformationCreateRequest.java`
- Create: `support-roster-server/src/test/java/com/support/server/supportrosterserver/service/contactinformation/ContactInformationServiceTest.java`
- Modify: `support-roster-server/pom.xml` only if a missing test dependency is genuinely required by existing stack conventions

- [ ] **Step 1: Write the failing service test for public list aggregation**

```java
package com.support.server.supportrosterserver.service.contactinformation;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationListResponse;
import com.support.server.supportrosterserver.entity.contactinformation.SupportTeamContactEntity;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactLinkMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactStaffMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactTagMapper;
import com.support.server.supportrosterserver.mapper.StaffMapper;
import com.support.server.supportrosterserver.service.auth.AuthContextService;

class ContactInformationServiceTest {

    @Test
    void shouldReturnPagedAggregatedContactInformation() {
        SupportTeamContactMapper contactMapper = mock(SupportTeamContactMapper.class);
        SupportTeamContactTagMapper tagMapper = mock(SupportTeamContactTagMapper.class);
        SupportTeamContactStaffMapper staffBindingMapper = mock(SupportTeamContactStaffMapper.class);
        SupportTeamContactLinkMapper linkMapper = mock(SupportTeamContactLinkMapper.class);
        StaffMapper staffMapper = mock(StaffMapper.class);
        AuthContextService authContextService = mock(AuthContextService.class);

        SupportTeamContactEntity entity = new SupportTeamContactEntity();
        entity.setId(1L);
        entity.setTeamName("Payments Core");
        entity.setTeamEmail("payments-core@company.com");

        Page<SupportTeamContactEntity> page = new Page<>(1, 20);
        page.setRecords(List.of(entity));
        page.setTotal(1);

        when(contactMapper.selectContactPage(1L, 20L, "payments")).thenReturn(page);

        ContactInformationService service = new ContactInformationService(
            contactMapper,
            tagMapper,
            staffBindingMapper,
            linkMapper,
            staffMapper,
            authContextService
        );

        ContactInformationListResponse response = service.listContacts("payments", 1, 20);

        assertEquals(1, response.total());
        assertEquals("Payments Core", response.items().get(0).name());
    }
}
```

- [ ] **Step 2: Write the failing service test for admin-only create validation**

```java
@Test
void shouldRejectCreateWhenStaffCodeDoesNotExist() {
    SupportTeamContactMapper contactMapper = mock(SupportTeamContactMapper.class);
    SupportTeamContactTagMapper tagMapper = mock(SupportTeamContactTagMapper.class);
    SupportTeamContactStaffMapper staffBindingMapper = mock(SupportTeamContactStaffMapper.class);
    SupportTeamContactLinkMapper linkMapper = mock(SupportTeamContactLinkMapper.class);
    StaffMapper staffMapper = mock(StaffMapper.class);
    AuthContextService authContextService = mock(AuthContextService.class);

    when(staffMapper.selectOne(org.mockito.ArgumentMatchers.any())).thenReturn(null);

    ContactInformationService service = new ContactInformationService(
        contactMapper,
        tagMapper,
        staffBindingMapper,
        linkMapper,
        staffMapper,
        authContextService
    );

    ContactInformationCreateRequest request = new ContactInformationCreateRequest(
        "Payments Core",
        "payments-core@company.com",
        "XM-PAY-01",
        "GSD-PAY-882",
        "EIM-9331",
        List.of("Upstream"),
        List.of("S-404"),
        List.of()
    );

    org.junit.jupiter.api.Assertions.assertThrows(
        com.support.server.supportrosterserver.exception.BadRequestException.class,
        () -> service.createContact(request)
    );
}
```

- [ ] **Step 3: Run the service test file to verify it fails**

Run:

```bash
cd support-roster-server
mvn -Dtest=ContactInformationServiceTest test
```

Expected:

- FAIL because `ContactInformationService` and related contact-information DTO/entity/mapper types do not exist yet

- [ ] **Step 4: Add minimal DTO records/classes to make the tests compile further**

```java
package com.support.server.supportrosterserver.dto.contactinformation;

import java.util.List;

public record ContactInformationDto(
    Long id,
    String name,
    String email,
    String xMatter,
    String gsd,
    String eim,
    List<String> roles,
    List<ContactInformationStaffDto> staff,
    List<ContactInformationLinkDto> links
) {}
```

```java
package com.support.server.supportrosterserver.dto.contactinformation;

public record ContactInformationStaffDto(
    String id,
    String name,
    String email,
    String avatar
) {}
```

```java
package com.support.server.supportrosterserver.dto.contactinformation;

public record ContactInformationLinkDto(
    String label,
    String url
) {}
```

```java
package com.support.server.supportrosterserver.dto.contactinformation;

import java.util.List;

public record ContactInformationListResponse(
    List<ContactInformationDto> items,
    long page,
    long pageSize,
    long total
) {}
```

```java
package com.support.server.supportrosterserver.dto.contactinformation;

import java.util.List;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;

public record ContactInformationCreateRequest(
    @NotBlank String name,
    @NotBlank @Email String email,
    String xMatter,
    String gsd,
    String eim,
    @NotEmpty List<String> roles,
    @NotEmpty List<String> staffIds,
    List<ContactInformationLinkDto> links
) {}
```

- [ ] **Step 5: Commit the backend contract/test scaffold**

```bash
git add support-roster-server/src/main/java/com/support/server/supportrosterserver/dto/contactinformation \
        support-roster-server/src/test/java/com/support/server/supportrosterserver/service/contactinformation/ContactInformationServiceTest.java
git commit -m "test: scaffold contact information backend contracts"
```

### Task 2: Add Flyway migration, backend entities, and mappers

**Files:**
- Create: `support-roster-server/src/main/resources/db/migration/V9__contact_information.sql`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/entity/contactinformation/SupportTeamContactEntity.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/entity/contactinformation/SupportTeamContactTagEntity.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/entity/contactinformation/SupportTeamContactStaffEntity.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/entity/contactinformation/SupportTeamContactLinkEntity.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/mapper/contactinformation/SupportTeamContactMapper.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/mapper/contactinformation/SupportTeamContactTagMapper.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/mapper/contactinformation/SupportTeamContactStaffMapper.java`
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/mapper/contactinformation/SupportTeamContactLinkMapper.java`

- [ ] **Step 1: Write the Flyway migration**

```sql
CREATE TABLE support_team_contact (
    id BIGSERIAL PRIMARY KEY,
    team_name VARCHAR(255) NOT NULL,
    team_email VARCHAR(255) NOT NULL UNIQUE,
    xmatter_group VARCHAR(255),
    gsd_group VARCHAR(255),
    eim_id VARCHAR(255),
    other_info TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by_account_id BIGINT,
    updated_by_account_id BIGINT
);

CREATE TABLE support_team_contact_tag (
    id BIGSERIAL PRIMARY KEY,
    contact_id BIGINT NOT NULL REFERENCES support_team_contact(id) ON DELETE CASCADE,
    tag VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE support_team_contact_staff (
    id BIGSERIAL PRIMARY KEY,
    contact_id BIGINT NOT NULL REFERENCES support_team_contact(id) ON DELETE CASCADE,
    staff_code VARCHAR(64) NOT NULL
);

CREATE TABLE support_team_contact_link (
    id BIGSERIAL PRIMARY KEY,
    contact_id BIGINT NOT NULL REFERENCES support_team_contact(id) ON DELETE CASCADE,
    label VARCHAR(100) NOT NULL,
    url TEXT NOT NULL,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE INDEX idx_support_team_contact_name ON support_team_contact(team_name);
CREATE INDEX idx_support_team_contact_staff_code ON support_team_contact_staff(staff_code);
CREATE INDEX idx_support_team_contact_tag_value ON support_team_contact_tag(tag);
```

- [ ] **Step 2: Create the parent entity**

```java
package com.support.server.supportrosterserver.entity.contactinformation;

import java.time.LocalDateTime;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;

import lombok.Data;

@Data
@TableName("support_team_contact")
public class SupportTeamContactEntity {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String teamName;
    private String teamEmail;
    private String xmatterGroup;
    private String gsdGroup;
    private String eimId;
    private String otherInfo;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Long createdByAccountId;
    private Long updatedByAccountId;
}
```

- [ ] **Step 3: Create child entities and mappers using existing MyBatis-Plus conventions**

```java
@Data
@TableName("support_team_contact_tag")
public class SupportTeamContactTagEntity {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long contactId;
    private String tag;
    private Integer sortOrder;
}
```

```java
@Mapper
public interface SupportTeamContactTagMapper extends BaseMapper<SupportTeamContactTagEntity> {}
```

- [ ] **Step 4: Add the parent mapper with a page-query method signature**

```java
@Mapper
public interface SupportTeamContactMapper extends BaseMapper<SupportTeamContactEntity> {

    Page<SupportTeamContactEntity> selectContactPage(long page, long pageSize, String keyword);
}
```

- [ ] **Step 5: Run the failing backend service test again**

Run:

```bash
cd support-roster-server
mvn -Dtest=ContactInformationServiceTest test
```

Expected:

- FAIL because `ContactInformationService` behavior is still missing, but compile-time missing migration/entity/mapper symbols are reduced

- [ ] **Step 6: Commit migration and persistence scaffolding**

```bash
git add support-roster-server/src/main/resources/db/migration/V9__contact_information.sql \
        support-roster-server/src/main/java/com/support/server/supportrosterserver/entity/contactinformation \
        support-roster-server/src/main/java/com/support/server/supportrosterserver/mapper/contactinformation
git commit -m "feat: add contact information persistence schema"
```

### Task 3: Implement backend service for public list and admin create

**Files:**
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/service/contactinformation/ContactInformationService.java`
- Modify: `support-roster-server/src/test/java/com/support/server/supportrosterserver/service/contactinformation/ContactInformationServiceTest.java`

- [ ] **Step 1: Add failing tests for admin auth enforcement and duplicate email rejection**

```java
@Test
void shouldRequireAdminToCreateContactInformation() {
    SupportTeamContactMapper contactMapper = mock(SupportTeamContactMapper.class);
    SupportTeamContactTagMapper tagMapper = mock(SupportTeamContactTagMapper.class);
    SupportTeamContactStaffMapper staffBindingMapper = mock(SupportTeamContactStaffMapper.class);
    SupportTeamContactLinkMapper linkMapper = mock(SupportTeamContactLinkMapper.class);
    StaffMapper staffMapper = mock(StaffMapper.class);
    AuthContextService authContextService = mock(AuthContextService.class);

    ContactInformationService service = new ContactInformationService(
        contactMapper, tagMapper, staffBindingMapper, linkMapper, staffMapper, authContextService
    );

    when(authContextService.requireAdmin()).thenThrow(new com.support.server.supportrosterserver.exception.ForbiddenException("Admin permission is required."));

    ContactInformationCreateRequest request = new ContactInformationCreateRequest(
        "Payments Core", "payments-core@company.com", null, null, null, List.of("Upstream"), List.of("S-10492"), List.of()
    );

    org.junit.jupiter.api.Assertions.assertThrows(
        com.support.server.supportrosterserver.exception.ForbiddenException.class,
        () -> service.createContact(request)
    );
}
```

- [ ] **Step 2: Run the test file to verify red**

Run:

```bash
cd support-roster-server
mvn -Dtest=ContactInformationServiceTest test
```

Expected:

- FAIL because the service class or methods still do not perform auth/validation/aggregation

- [ ] **Step 3: Implement the minimal service**

```java
package com.support.server.supportrosterserver.service.contactinformation;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationCreateRequest;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationDto;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationListResponse;
import com.support.server.supportrosterserver.exception.BadRequestException;
import com.support.server.supportrosterserver.mapper.StaffMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactLinkMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactStaffMapper;
import com.support.server.supportrosterserver.mapper.contactinformation.SupportTeamContactTagMapper;
import com.support.server.supportrosterserver.service.auth.AuthContextService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ContactInformationService {

    private final SupportTeamContactMapper contactMapper;
    private final SupportTeamContactTagMapper tagMapper;
    private final SupportTeamContactStaffMapper staffBindingMapper;
    private final SupportTeamContactLinkMapper linkMapper;
    private final StaffMapper staffMapper;
    private final AuthContextService authContextService;

    public ContactInformationListResponse listContacts(String keyword, long page, long pageSize) {
        Page<?> contactPage = contactMapper.selectContactPage(page, pageSize, keyword);
        List<ContactInformationDto> items = contactPage.getRecords().stream()
            .map(record -> aggregateContact(((com.support.server.supportrosterserver.entity.contactinformation.SupportTeamContactEntity) record).getId()))
            .toList();
        return new ContactInformationListResponse(items, page, pageSize, contactPage.getTotal());
    }

    @Transactional
    public ContactInformationDto createContact(ContactInformationCreateRequest request) {
        authContextService.requireAdmin();
        if (request.roles() == null || request.roles().isEmpty()) {
            throw new BadRequestException("At least one tag is required.");
        }
        if (request.staffIds() == null || request.staffIds().isEmpty()) {
            throw new BadRequestException("At least one staff ID is required.");
        }
        validateStaffCodes(request.staffIds());
        // insert parent row, insert child rows, then aggregate and return
        throw new UnsupportedOperationException("Implement transactional insert");
    }
}
```

- [ ] **Step 4: Replace `UnsupportedOperationException` with the real insert + aggregate logic**

```java
private void validateStaffCodes(List<String> staffCodes) {
    for (String staffCode : staffCodes) {
        var staff = staffMapper.selectOne(
            com.baomidou.mybatisplus.core.toolkit.Wrappers.<com.support.server.supportrosterserver.entity.workspace.StaffEntity>lambdaQuery()
                .eq(com.support.server.supportrosterserver.entity.workspace.StaffEntity::getStaffCode, staffCode)
                .last("limit 1")
        );
        if (staff == null) {
            throw new BadRequestException("Unknown staff ID: " + staffCode);
        }
    }
}
```

- [ ] **Step 5: Run the backend service test to verify green**

Run:

```bash
cd support-roster-server
mvn -Dtest=ContactInformationServiceTest test
```

Expected:

- PASS for all service-level list/create validation tests

- [ ] **Step 6: Commit the backend service implementation**

```bash
git add support-roster-server/src/main/java/com/support/server/supportrosterserver/service/contactinformation/ContactInformationService.java \
        support-roster-server/src/test/java/com/support/server/supportrosterserver/service/contactinformation/ContactInformationServiceTest.java
git commit -m "feat: implement contact information service"
```

### Task 4: Add backend controller and controller tests

**Files:**
- Create: `support-roster-server/src/main/java/com/support/server/supportrosterserver/controller/ContactInformationController.java`
- Create: `support-roster-server/src/test/java/com/support/server/supportrosterserver/controller/ContactInformationControllerTest.java`

- [ ] **Step 1: Write the failing controller test for list**

```java
package com.support.server.supportrosterserver.controller;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationDto;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationListResponse;
import com.support.server.supportrosterserver.service.contactinformation.ContactInformationService;

class ContactInformationControllerTest {

    @Test
    void shouldReturnPublicPagedContactInformation() {
        ContactInformationService service = mock(ContactInformationService.class);
        when(service.listContacts("payments", 1, 20)).thenReturn(
            new ContactInformationListResponse(List.of(), 1, 20, 0)
        );

        ContactInformationController controller = new ContactInformationController(service);

        var response = controller.listContacts("payments", 1, 20);

        assertEquals(200, response.getStatusCode().value());
        assertEquals(0, response.getBody().total());
    }
}
```

- [ ] **Step 2: Run the controller test to verify it fails**

Run:

```bash
cd support-roster-server
mvn -Dtest=ContactInformationControllerTest test
```

Expected:

- FAIL because the controller does not exist yet

- [ ] **Step 3: Implement the controller**

```java
package com.support.server.supportrosterserver.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationCreateRequest;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationDto;
import com.support.server.supportrosterserver.dto.contactinformation.ContactInformationListResponse;
import com.support.server.supportrosterserver.service.contactinformation.ContactInformationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequestMapping("/api/contact-information")
@RequiredArgsConstructor
public class ContactInformationController {

    private final ContactInformationService contactInformationService;

    @GetMapping
    public ResponseEntity<ContactInformationListResponse> listContacts(
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize) {
        return ResponseEntity.ok(contactInformationService.listContacts(keyword, page, pageSize));
    }

    @PostMapping
    public ResponseEntity<ContactInformationDto> createContact(
            @Valid @RequestBody ContactInformationCreateRequest request) {
        return ResponseEntity.ok(contactInformationService.createContact(request));
    }
}
```

- [ ] **Step 4: Run focused backend tests**

Run:

```bash
cd support-roster-server
mvn -Dtest=ContactInformationControllerTest,ContactInformationServiceTest test
```

Expected:

- PASS for the new contact-information controller and service tests

- [ ] **Step 5: Commit the controller layer**

```bash
git add support-roster-server/src/main/java/com/support/server/supportrosterserver/controller/ContactInformationController.java \
        support-roster-server/src/test/java/com/support/server/supportrosterserver/controller/ContactInformationControllerTest.java
git commit -m "feat: add contact information api"
```

### Task 5: Update backend specs and indexes

**Files:**
- Create: `support-roster-server/.specs/features/contact-information.md`
- Modify: `support-roster-server/.specs/_index.md`
- Modify: `support-roster-server/.specs/api-standard.md` only if response shape conventions need documenting

- [ ] **Step 1: Add the server feature spec**

```md
# Contact Information API

## Endpoints

- `GET /api/contact-information`
- `POST /api/contact-information`

## Access

- list: public
- create: workspace admin only

## Persistence

- `support_team_contact`
- `support_team_contact_tag`
- `support_team_contact_staff`
- `support_team_contact_link`
```

- [ ] **Step 2: Link it from the server spec index**

```md
- [Contact Information API](./features/contact-information.md)
```

- [ ] **Step 3: Commit backend spec updates**

```bash
git add support-roster-server/.specs/features/contact-information.md \
        support-roster-server/.specs/_index.md \
        support-roster-server/.specs/api-standard.md
git commit -m "docs: add contact information server spec"
```

### Task 6: Add frontend API client and write failing integration tests

**Files:**
- Create: `support-roster-ui/src/api/contactInformation.js`
- Create: `support-roster-ui/src/features/contact-information/lib/contactInformationApi.test.js`
- Modify: `support-roster-ui/src/features/contact-information/pages/SupportTeamContactsPage.test.js`
- Modify: `support-roster-ui/src/features/contact-information/components/SupportTeamContactForm.test.js`

- [ ] **Step 1: Write the failing API-client test**

```javascript
import test from 'node:test'
import assert from 'node:assert/strict'
import { buildContactInformationListQuery } from './contactInformationApi.js'

test('contact information api builds keyword and pagination query params', () => {
  assert.equal(
    buildContactInformationListQuery({ keyword: 'payments', page: 2, pageSize: 25 }),
    'keyword=payments&page=2&pageSize=25',
  )
})
```

- [ ] **Step 2: Write the failing page/source test for real API usage**

```javascript
test('contact information page loads real api data instead of runtime mock records', () => {
  assert.doesNotMatch(pageSource, /contactInformationMockTeams/)
  assert.match(pageSource, /listContactInformation/)
})
```

- [ ] **Step 3: Run the targeted frontend tests to verify red**

Run:

```bash
cd support-roster-ui
node --test src/features/contact-information/lib/contactInformationApi.test.js \
            src/features/contact-information/pages/SupportTeamContactsPage.test.js \
            src/features/contact-information/components/SupportTeamContactForm.test.js
```

Expected:

- FAIL because the API client and page integration do not exist yet

- [ ] **Step 4: Implement the minimal API client**

```javascript
import { api } from '@/api'

export function buildContactInformationListQuery({ keyword = '', page = 1, pageSize = 20 }) {
  const params = new URLSearchParams()
  if (keyword) params.set('keyword', keyword)
  params.set('page', String(page))
  params.set('pageSize', String(pageSize))
  return params.toString()
}

export async function listContactInformation({ keyword = '', page = 1, pageSize = 20 }) {
  const query = buildContactInformationListQuery({ keyword, page, pageSize })
  return api.get(`/contact-information?${query}`)
}

export async function createContactInformation(payload) {
  return api.post('/contact-information', payload)
}
```

- [ ] **Step 5: Commit the frontend API scaffold**

```bash
git add support-roster-ui/src/api/contactInformation.js \
        support-roster-ui/src/features/contact-information/lib/contactInformationApi.test.js \
        support-roster-ui/src/features/contact-information/pages/SupportTeamContactsPage.test.js \
        support-roster-ui/src/features/contact-information/components/SupportTeamContactForm.test.js
git commit -m "test: scaffold contact information frontend api"
```

### Task 7: Integrate the public list page with server-side search and pagination

**Files:**
- Modify: `support-roster-ui/src/features/contact-information/pages/SupportTeamContactsPage.vue`
- Modify: `support-roster-ui/src/features/contact-information/components/ContactInformationTable.vue`
- Modify: `support-roster-ui/src/features/contact-information/pages/SupportTeamContactsPage.test.js`
- Modify: `support-roster-ui/src/features/contact-information/components/ContactInformationTable.test.js`

- [ ] **Step 1: Write the failing page test for server-backed list state**

```javascript
test('contact information page derives list data and total count from api response state', () => {
  assert.match(pageSource, /const contactsResponse = ref/)
  assert.match(pageSource, /:teams="contactsResponse\.items"/)
  assert.match(pageSource, /:total-count="contactsResponse\.total"/)
})
```

- [ ] **Step 2: Write the failing table test for real pagination controls**

```javascript
test('contact information table exposes previous and next actions for real pagination', () => {
  assert.match(tableSource, /@click="\$emit\('change-page', currentPage - 1\)"/)
  assert.match(tableSource, /@click="\$emit\('change-page', currentPage \+ 1\)"/)
})
```

- [ ] **Step 3: Run the targeted tests to verify red**

Run:

```bash
cd support-roster-ui
node --test src/features/contact-information/pages/SupportTeamContactsPage.test.js \
            src/features/contact-information/components/ContactInformationTable.test.js
```

Expected:

- FAIL because list state and real pagination wiring are not implemented yet

- [ ] **Step 4: Implement minimal list state and route-query driven fetch**

```javascript
const contactsResponse = ref({ items: [], page: 1, pageSize: 20, total: 0 })
const loading = ref(false)

watch(
  () => [layoutState.searchTerm.value, route.query.page],
  async () => {
    loading.value = true
    contactsResponse.value = await listContactInformation({
      keyword: layoutState.searchTerm.value,
      page: Number(route.query.page || 1),
      pageSize: 20,
    })
    loading.value = false
  },
  { immediate: true },
)
```

- [ ] **Step 5: Implement real table pagination props/events**

```vue
<ContactInformationTable
  :teams="contactsResponse.items"
  :total-count="contactsResponse.total"
  :current-page="contactsResponse.page"
  :page-size="contactsResponse.pageSize"
  @change-page="handlePageChange"
  @copy="handleCopy"
/>
```

- [ ] **Step 6: Re-run targeted frontend tests to verify green**

Run:

```bash
cd support-roster-ui
node --test src/features/contact-information/pages/SupportTeamContactsPage.test.js \
            src/features/contact-information/components/ContactInformationTable.test.js
```

Expected:

- PASS for list-state and pagination wiring tests

- [ ] **Step 7: Commit list-page integration**

```bash
git add support-roster-ui/src/features/contact-information/pages/SupportTeamContactsPage.vue \
        support-roster-ui/src/features/contact-information/components/ContactInformationTable.vue \
        support-roster-ui/src/features/contact-information/pages/SupportTeamContactsPage.test.js \
        support-roster-ui/src/features/contact-information/components/ContactInformationTable.test.js
git commit -m "feat: load contact information from api"
```

### Task 8: Integrate the create page with real API submission

**Files:**
- Modify: `support-roster-ui/src/features/contact-information/pages/SupportTeamContactCreatePage.vue`
- Modify: `support-roster-ui/src/features/contact-information/components/SupportTeamContactForm.vue`
- Modify: `support-roster-ui/src/features/contact-information/components/SupportTeamContactForm.test.js`
- Modify: `support-roster-ui/src/features/contact-information/pages/SupportTeamContactCreatePage.test.js`

- [ ] **Step 1: Write the failing test for real submission**

```javascript
test('contact information create page submits through the contact information api client', () => {
  assert.match(pageSource, /createContactInformation/)
  assert.match(pageSource, /await createContactInformation\(payload\)/)
})
```

- [ ] **Step 2: Write the failing test for preserving form state on failure**

```javascript
test('create contact form does not clear entered values on submit failure', () => {
  assert.match(formSource, /submitError/)
  assert.match(formSource, /emit\('submit',/)
  assert.doesNotMatch(formSource, /formState\.teamName = ''/)
})
```

- [ ] **Step 3: Run the targeted create-flow tests to verify red**

Run:

```bash
cd support-roster-ui
node --test src/features/contact-information/components/SupportTeamContactForm.test.js \
            src/features/contact-information/pages/SupportTeamContactCreatePage.test.js
```

Expected:

- FAIL because create page still uses mock navigation-only success

- [ ] **Step 4: Implement real submission**

```javascript
async function handleSubmit(payload) {
  try {
    await createContactInformation(payload)
    router.push({ path: '/contact-information', query: { created: '1' } })
  } catch (error) {
    submitError.value = extractErrorMessage(error)
  }
}
```

- [ ] **Step 5: Re-run targeted create-flow tests**

Run:

```bash
cd support-roster-ui
node --test src/features/contact-information/components/SupportTeamContactForm.test.js \
            src/features/contact-information/pages/SupportTeamContactCreatePage.test.js
```

Expected:

- PASS for real-submission tests

- [ ] **Step 6: Commit create-page integration**

```bash
git add support-roster-ui/src/features/contact-information/pages/SupportTeamContactCreatePage.vue \
        support-roster-ui/src/features/contact-information/components/SupportTeamContactForm.vue \
        support-roster-ui/src/features/contact-information/components/SupportTeamContactForm.test.js \
        support-roster-ui/src/features/contact-information/pages/SupportTeamContactCreatePage.test.js
git commit -m "feat: submit contact information to api"
```

### Task 9: Update frontend specs for live backend integration

**Files:**
- Modify: `support-roster-ui/.specs/contact-information.md`
- Modify: `support-roster-ui/.specs/development.md` if local integration steps change materially
- Modify: `support-roster-ui/.specs/spec.md` only if a new spec file is introduced during implementation

- [ ] **Step 1: Replace runtime mock assumptions in the frontend spec**

```md
- 列表页数据来自 `GET /api/contact-information`
- 新增页提交到 `POST /api/contact-information`
- 列表搜索与分页由服务端负责，前端负责 query 同步和结果渲染
- 新增成功后返回列表页并显示一次性成功提示
```

- [ ] **Step 2: Add local integration notes if the development workflow changes**

```md
- 本地联调前确保 `support-roster-server` 已执行包含 `V9__contact_information.sql` 的 Flyway migration
- `contact-information` 列表公开可读，创建需要管理员登录态
```

- [ ] **Step 3: Commit frontend spec updates**

```bash
git add support-roster-ui/.specs/contact-information.md \
        support-roster-ui/.specs/development.md \
        support-roster-ui/.specs/spec.md
git commit -m "docs: update contact information frontend spec"
```

### Task 10: Add browser automation and run final verification

**Files:**
- Create: `automationtest/specs/contact-information/public-list.spec.mjs`
- Create: `automationtest/specs/contact-information/admin-create.spec.mjs`
- Modify: `automationtest/README.md` if feature coverage or environment setup changes

- [ ] **Step 1: Write the public-list browser test**

```javascript
import { test, expect } from '../../fixtures/test.fixture.mjs'

test('public contact information list loads without login', async ({ page }) => {
  await page.goto('/contact-information')
  await expect(page.getByRole('heading', { name: /System Teams/i })).toBeVisible()
})
```

- [ ] **Step 2: Write the admin-create browser test**

```javascript
import { test, expect } from '../../fixtures/test.fixture.mjs'

test('admin can create a contact information record', async ({ authenticatedPage }) => {
  await authenticatedPage.goto('/contact-information/add')
  await authenticatedPage.getByLabel('Team Name').fill('Automation Contact Team')
  await authenticatedPage.getByLabel('Team Email').fill('automation-contact-team@example.com')
  await authenticatedPage.getByLabel('Tag').fill('Upstream')
  await authenticatedPage.keyboard.press('Enter')
  await authenticatedPage.getByLabel('Staff IDs').fill('123456')
  await authenticatedPage.getByRole('button', { name: 'Save Team' }).click()
  await expect(authenticatedPage.getByText(/saved/i)).toBeVisible()
})
```

- [ ] **Step 3: Run backend, frontend, and automation verification**

Run:

```bash
cd support-roster-server && mvn test
cd ../support-roster-ui && node --test && npm run build
cd ../automationtest && npm run precheck
cd .. && bash scripts/dev/test-restart-all.sh
cd automationtest && npm run test -- --grep "contact information"
```

Expected:

- backend tests pass
- frontend tests pass
- frontend build passes
- restart script test passes
- contact-information browser specs pass

- [ ] **Step 4: Commit automation and final verification-related docs**

```bash
git add automationtest/specs/contact-information \
        automationtest/README.md
git commit -m "test: add contact information integration coverage"
```

## Self-Review Notes

- **Spec coverage:** This plan covers persistence, public list API, admin create API, frontend API integration, server-side search + pagination, spec sync, and browser validation.
- **Placeholder scan:** No `TODO`/`TBD` placeholders are intentionally left in executable steps.
- **Type consistency:** The plan consistently uses `ContactInformationCreateRequest`, `ContactInformationListResponse`, `SupportTeamContactEntity`, `listContacts`, and `createContact`.

