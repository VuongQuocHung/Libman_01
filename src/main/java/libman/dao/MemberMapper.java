package libman.dao;

import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Member5;

/** Đổ các cột chung của tblMember5 vào đối tượng Member5 (hoặc lớp con của nó). */
final class MemberMapper {

    private MemberMapper() {
    }

    /** Danh sách cột của tblMember5 (bí danh m), dùng chung cho các câu SELECT. */
    static final String MEMBER_COLUMNS = "m.id, m.username, m.fullName, m.birthDate, "
            + "m.email, m.phone, m.address, m.is_active";

    static void fill(Member5 member, ResultSet rs) throws SQLException {
        member.setId(rs.getInt("id"));
        member.setUsername(rs.getString("username"));
        member.setFullName(rs.getString("fullName"));
        member.setBirthDate(rs.getDate("birthDate"));
        member.setEmail(rs.getString("email"));
        member.setPhone(rs.getString("phone"));
        member.setAddress(rs.getString("address"));
        member.setActive(rs.getBoolean("is_active"));
    }
}
