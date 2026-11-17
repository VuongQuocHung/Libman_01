package libman.dao;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import libman.model.Reader5;
import libman.model.ReaderCard5;
import libman.model.Status5;
import libman.util.DBUtil;
import libman.util.Html;

public class ReaderCardDAO5 {

    private static final String SELECT =
            "SELECT c.id, c.cardCode, c.registrationDate, c.expiryDate, c.cardStatus, c.photo, "
            + "r.id AS readerId, r.readerCode "
            + "FROM tblReaderCard5 c JOIN tblReader5 r ON r.id = c.readerId ";

    /** Tìm thẻ theo mã thẻ (quét thẻ); null nếu không có. Đối tượng Reader5 bên trong chỉ có id và mã độc giả. */
    public ReaderCard5 getCardByCode(String cardCode) throws SQLException {
        try (Connection c = DBUtil.getConnection();
             PreparedStatement ps = c.prepareStatement(SELECT + "WHERE c.cardCode = ?")) {
            ps.setString(1, cardCode);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /**
     * Tìm thẻ theo mã độc giả. Ưu tiên thẻ đang dùng được, sau đó thẻ có ngày hết hạn muộn nhất;
     * null nếu độc giả chưa có thẻ.
     */
    public ReaderCard5 getCardByReaderCode(String readerCode) throws SQLException {
        String sql = SELECT + "WHERE r.readerCode = ? "
                + "ORDER BY (c.cardStatus = ? AND c.expiryDate >= ?) DESC, c.expiryDate DESC LIMIT 1";
        try (Connection c = DBUtil.getConnection(); PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, readerCode);
            ps.setString(2, Status5.ACTIVE);
            ps.setDate(3, Html.today());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    private static ReaderCard5 map(ResultSet rs) throws SQLException {
        ReaderCard5 card = new ReaderCard5();
        card.setId(rs.getInt("id"));
        card.setCardCode(rs.getString("cardCode"));
        card.setRegistrationDate(rs.getDate("registrationDate"));
        card.setExpiryDate(rs.getDate("expiryDate"));
        card.setCardStatus(rs.getString("cardStatus"));
        card.setPhoto(rs.getString("photo"));
        Reader5 r = new Reader5();
        r.setId(rs.getInt("readerId"));
        r.setReaderCode(rs.getString("readerCode"));
        card.setReader(r);
        return card;
    }
}
