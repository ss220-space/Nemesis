pub fn map_to_string(map: &dmmtools::dmm::Map) -> eyre::Result<String> {
    let mut vec = vec![];
    map.to_writer(&mut vec)?;
    let string = String::from_utf8(vec)?;

    let re = regex::Regex::new(r#"(=\s*)\{(.*)\}"#)?;
    let result = re.replace_all(&string, |caps: &regex::Captures| {
        let prefix = &caps[1];
        let inner = &caps[2];

        if inner.contains("\\\"") {
            format!("{}{}", prefix, inner)
        } else {
            format!("{}{{{}}}", prefix, inner)
        }
    });

    Ok(result.to_string())
}
